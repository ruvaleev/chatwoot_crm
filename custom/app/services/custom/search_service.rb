module Custom::SearchService
  private

  def filter_conversations
    crm_phone_lookup? ? super.none : super.crm_visible_to(current_user)
  end

  def message_base_query
    return super unless current_user.crm_freelancer?

    super.where(conversation_id: current_account.conversations.crm_visible_to(current_user).select(:id))
  end

  def filter_contacts
    crm_phone_lookup? ? super.none : super.crm_visible_to(current_user)
  end

  # Conversation and contact search match phone numbers; freelancers must not confirm a number that way.
  def crm_phone_lookup?
    current_user.crm_freelancer? && Custom::PhoneScrubber.phone_like?(search_query)
  end
end
