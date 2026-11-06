module Custom::SearchService
  private

  def filter_conversations
    super.crm_visible_to(current_user)
  end

  def message_base_query
    return super unless current_user.crm_freelancer?

    super.where(conversation_id: current_account.conversations.crm_visible_to(current_user).select(:id))
  end

  def filter_contacts
    super.crm_visible_to(current_user)
  end
end
