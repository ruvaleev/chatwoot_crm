module Custom::Concerns::Conversation
  extend ActiveSupport::Concern

  # Deal status of the conversation (crm/design/brief.md). Freelancers move a deal only within their part of it.
  CRM_STATUSES = %w[new qualifying handed_off in_work won lost spam].freeze
  CRM_FREELANCER_STATUSES = %w[in_work won lost spam].freeze
  CRM_DEAL_FIELDS = %w[budget deal_amount lost_reason].freeze
  # Evolution API's service contact: it posts QR codes and connection statuses (src/.../chatwoot.service.ts, '123456').
  CRM_SERVICE_CONTACT_PHONE = '+123456'.freeze

  # Assignment only, not participation: assigning makes a user a permanent participant (ParticipationListener),
  # so a freelancer must lose access as soon as the conversation is reassigned.
  included do
    scope :crm_visible_to, ->(user) { user.crm_freelancer? ? where(assignee_id: user.id) : all }
    scope :crm_client_chats, -> { where.not(contact_id: Contact.where(phone_number: CRM_SERVICE_CONTACT_PHONE).select(:id)) }
    # The client wrote last and nobody answered yet.
    scope :crm_waiting, -> { where.not(waiting_since: nil) }

    has_many :crm_hidden_conversations, class_name: 'Custom::HiddenConversation', dependent: :delete_all

    scope :crm_with_status, lambda { |status|
      value = Arel::Nodes::InfixOperation.new('->>', arel_table[:custom_attributes], Arel::Nodes.build_quoted('crm_status'))
      status == 'new' ? where(value.eq('new').or(value.eq(nil))) : where(value.eq(status))
    }
    # Client name, phone (only when allowed) or message text.
    scope :crm_matching, lambda { |query, phone:|
      pattern = "%#{sanitize_sql_like(query)}%"
      contacts = Contact.where(Contact.arel_table[:name].matches(pattern))
      contacts = contacts.or(Contact.where(Contact.arel_table[:phone_number].matches(pattern))) if phone
      messages = Message.where(Message.arel_table[:content].matches(pattern))
      where(contact_id: contacts.select(:id)).or(where(id: messages.select(:conversation_id)))
    }
  end

  def crm_visible_to?(user)
    !user.crm_freelancer? || assignee_id == user.id
  end

  def crm_status
    custom_attributes['crm_status'] || 'new'
  end

  def crm_deal
    CRM_DEAL_FIELDS.index_with { |field| custom_attributes["crm_#{field}"] }
  end

  # The manager's brief is a private note; the hand-off (stage D2) stores its id here.
  def crm_brief
    messages.find_by(id: custom_attributes['crm_brief_message_id'], private: true)
  end
end
