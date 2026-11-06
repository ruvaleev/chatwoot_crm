# Freelancers see only contacts of conversations assigned to them (see Custom::Concerns::Conversation).
module Custom::Concerns::Contact
  extend ActiveSupport::Concern

  included do
    scope :crm_visible_to, ->(user) { user.crm_freelancer? ? where(id: Conversation.crm_visible_to(user).select(:contact_id)) : all }
  end

  def crm_visible_to?(user)
    !user.crm_freelancer? || conversations.crm_visible_to(user).exists?
  end
end
