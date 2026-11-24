# Browser push for a new client message (crm/PRD.md, stage P): to whoever the chat is assigned to, to every manager
# while it is nobody's. Our own text and link, not Chatwoot's: a freelancer never sees the client's number, even when
# the contact is named after it, and the notification opens the chat in /crm. Chatwoot's own push is off
# (Custom::Notification). Delivery goes to the browser's push service (H8), encrypted for the device.
class Custom::Push
  BODY_LENGTH = 120
  TIMEOUT_SECONDS = 5

  pattr_initialize :message

  def perform
    recipients.each do |user|
      payload = payload_for(user).to_json
      user.notification_subscriptions.browser_push.find_each { |subscription| deliver(subscription, payload) }
    end
  end

  private

  def conversation
    message.conversation
  end

  def recipients
    conversation.assignee ? [conversation.assignee] : conversation.account.users.reject(&:crm_freelancer?)
  end

  def payload_for(user)
    { title: title_for(user), body: body, tag: "crm-chat-#{conversation.id}", url: "/crm/chats/#{conversation.id}" }
  end

  def title_for(user)
    name = conversation.contact.name
    user.crm_freelancer? ? Custom::PhoneScrubber.new(locale: locale).scrub('name' => name)['name'] : name
  end

  def body
    message.content.presence&.truncate(BODY_LENGTH) || I18n.t('crm.push.attachment', locale: locale)
  end

  def locale
    conversation.account.crm_settings['notification_locale']
  end

  def deliver(subscription, payload)
    attributes = subscription.subscription_attributes
    WebPush.payload_send(message: payload, endpoint: attributes['endpoint'], p256dh: attributes['p256dh'], auth: attributes['auth'],
                         vapid: { subject: ENV.fetch('FRONTEND_URL'), public_key: VapidService.public_key,
                                  private_key: VapidService.private_key },
                         ssl_timeout: TIMEOUT_SECONDS, open_timeout: TIMEOUT_SECONDS, read_timeout: TIMEOUT_SECONDS)
  rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription, WebPush::Unauthorized
    # The browser dropped this subscription (app removed, permission revoked): stop sending to it.
    subscription.destroy!
  rescue StandardError => e
    # One device failing (timeout, rate limit, push service down) must not cost the others their notification.
    Rails.logger.error("CRM push to subscription #{subscription.id} failed: #{e.class}: #{e.message}")
  end
end
