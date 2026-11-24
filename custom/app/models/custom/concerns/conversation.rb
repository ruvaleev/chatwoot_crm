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
    # Message text, and client name or phone when allowed.
    scope :crm_matching, lambda { |query, contacts:, phone:|
      pattern = "%#{sanitize_sql_like(query)}%"
      by_messages = where(id: Message.where(Message.arel_table[:content].matches(pattern)).select(:conversation_id))
      next by_messages unless contacts

      matching = Contact.where(Contact.arel_table[:name].matches(pattern))
      matching = matching.or(Contact.where(Contact.arel_table[:phone_number].matches(pattern))) if phone
      where(contact_id: matching.select(:id)).or(by_messages)
    }
  end

  # What a chat list row shows, for a whole page at once instead of a few queries per row.
  class_methods do
    def crm_last_messages(ids)
      # reorder(nil): messages come ordered by default, which a grouped query can't carry.
      last_ids = Message.where(conversation_id: ids, private: false).where.not(message_type: :activity).reorder(nil)
                        .group(:conversation_id).select(Message.arel_table[:id].maximum)
      Message.where(id: last_ids).includes(:attachments).index_by(&:conversation_id)
    end

    # Like Chatwoot's unread_incoming_messages: incoming since the agents last looked, at most 10.
    def crm_unread_counts(ids)
      seen = arel_table[:agent_last_seen_at]
      Message.incoming.joins(:conversation).where(conversation_id: ids).reorder(nil)
             .where(Message.arel_table[:created_at].gt(seen).or(seen.eq(nil)))
             .group(:conversation_id).count.transform_values { |count| [count, 10].min }
    end
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
