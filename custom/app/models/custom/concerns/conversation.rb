module Custom::Concerns::Conversation
  extend ActiveSupport::Concern

  # Deal status of the conversation (crm/design/brief.md). Freelancers move a deal only within their part of it.
  CRM_STATUSES = %w[new qualifying handed_off in_work won lost spam].freeze
  CRM_FREELANCER_STATUSES = %w[in_work won lost spam].freeze
  CRM_DEAL_FIELDS = %w[budget deal_amount lost_reason].freeze

  # Assignment only, not participation: assigning makes a user a permanent participant (ParticipationListener),
  # so a freelancer must lose access as soon as the conversation is reassigned.
  included do
    scope :crm_visible_to, ->(user) { user.crm_freelancer? ? where(assignee_id: user.id) : all }
    # The client wrote last and nobody answered yet.
    scope :crm_waiting, -> { where.not(waiting_since: nil) }

    has_many :crm_hidden_conversations, class_name: 'Custom::HiddenConversation', dependent: :delete_all
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
