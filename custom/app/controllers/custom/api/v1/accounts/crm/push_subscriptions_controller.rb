# Push on this device (crm/PRD.md, stage P). Chatwoot's builder keeps one subscription per device (signing in as
# someone else on the same phone moves it to them); signing out removes it, so the device gets nobody's messages.
class Custom::Api::V1::Accounts::Crm::PushSubscriptionsController < Api::V1::Accounts::BaseController
  def create
    attributes = params.permit(:endpoint, :p256dh, :auth).to_h
    return render_could_not_create_error('push_subscription_invalid') unless attributes.values_at('endpoint', 'p256dh', 'auth').all?(&:present?)

    NotificationSubscriptionBuilder.new(user: Current.user,
                                        params: { subscription_type: 'browser_push', subscription_attributes: attributes }.with_indifferent_access)
                                   .perform
    head :no_content
  end

  def destroy
    Current.user.notification_subscriptions.browser_push.where(identifier: params.require(:endpoint)).destroy_all
    head :no_content
  end
end
