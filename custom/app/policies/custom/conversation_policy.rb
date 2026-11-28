module Custom::ConversationPolicy
  def show?
    super && (!user.is_a?(User) || record.crm_visible_to?(user))
  end
end
