# Notifications render their conversation as it is now, so after a reassignment they would keep showing
# a freelancer new messages of a conversation they no longer see.
module Custom::NotificationFinder
  private

  def find_all_notifications
    super
    return unless current_user.crm_freelancer?

    @notifications = @notifications.where(primary_actor_type: 'Conversation',
                                          primary_actor_id: Conversation.crm_visible_to(current_user).select(:id))
  end
end
