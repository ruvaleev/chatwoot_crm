# Chatwoot's own push links to the old /app and doesn't mask client numbers for freelancers: Custom::Push sends ours.
# Email and in-app notifications stay as they are.
module Custom::Notification
  private

  def user_subscribed_to_notification?(delivery_type)
    delivery_type != 'push' && super
  end
end
