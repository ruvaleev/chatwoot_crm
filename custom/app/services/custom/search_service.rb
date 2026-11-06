module Custom::SearchService
  private

  def filter_conversations
    current_user.crm_freelancer? ? super.where(assignee_id: current_user.id) : super
  end

  def message_base_query
    return super unless current_user.crm_freelancer?

    super.where(conversation_id: current_account.conversations.where(assignee_id: current_user.id).select(:id))
  end
end
