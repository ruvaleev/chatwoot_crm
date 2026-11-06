module Custom::Concerns::Conversation
  extend ActiveSupport::Concern

  # Assignment only, not participation: assigning makes a user a permanent participant (ParticipationListener),
  # so a freelancer must lose access as soon as the conversation is reassigned.
  included do
    scope :crm_visible_to, ->(user) { user.crm_freelancer? ? where(assignee_id: user.id) : all }
  end

  def crm_visible_to?(user)
    !user.crm_freelancer? || assignee_id == user.id
  end
end
