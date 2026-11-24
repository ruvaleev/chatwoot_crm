require 'rails_helper'

describe Custom::Push do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let!(:manager) { create(:user, account: account, role: :administrator) }
  let!(:freelancer) { create(:user, account: account, role: :agent, custom_attributes: { crm_freelancer: true }) }
  let(:contact) { create(:contact, account: account, name: 'Anna Petrova') }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let(:message) do
    create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, content: 'Hello, is it free?')
  end
  let(:sent) { [] }

  def subscribe(user, endpoint)
    create(:notification_subscription, user: user, identifier: endpoint,
                                       subscription_attributes: { endpoint: endpoint, p256dh: 'key', auth: 'secret' })
  end

  before do
    subscribe(manager, 'https://push.test/manager')
    subscribe(freelancer, 'https://push.test/freelancer')
    allow(WebPush).to receive(:payload_send) { |**args| sent << [args[:endpoint], JSON.parse(args[:message])] }
  end

  around { |example| with_modified_env(FRONTEND_URL: 'https://chat.test') { example.run } }

  it 'notifies the managers about a chat that is nobody’s, opening it in /crm' do
    described_class.new(message).perform

    expect(sent).to eq([['https://push.test/manager', { 'title' => 'Anna Petrova', 'body' => 'Hello, is it free?',
                                                        'tag' => "crm-chat-#{conversation.id}", 'url' => "/crm/chats/#{conversation.id}" }]])
  end

  it 'notifies only the assignee of an assigned chat' do
    conversation.update!(assignee: freelancer)

    described_class.new(message).perform

    expect(sent.map(&:first)).to eq(['https://push.test/freelancer'])
  end

  it 'never shows a freelancer the client’s number' do
    contact.update!(name: '+7 999 123-45-67')
    conversation.update!(assignee: freelancer)

    described_class.new(message).perform

    expect(sent.dig(0, 1, 'title')).to eq('Клиент •••67')
  end

  it 'names an attachment without text' do
    message.update!(content: nil)

    described_class.new(message).perform

    expect(sent.dig(0, 1, 'body')).to eq('Вложение')
  end

  it 'forgets a subscription the browser dropped' do
    allow(WebPush).to receive(:payload_send).and_raise(WebPush::ExpiredSubscription.new(instance_double(Net::HTTPGone, body: ''), 'push.test'))

    described_class.new(message).perform

    expect(manager.notification_subscriptions).to be_empty
  end

  it 'still notifies the others when one device fails' do
    other_manager = create(:user, account: account, role: :administrator)
    subscribe(other_manager, 'https://push.test/other-manager')
    allow(WebPush).to receive(:payload_send).with(hash_including(endpoint: 'https://push.test/manager')).and_raise(Net::ReadTimeout)

    described_class.new(message).perform

    expect(sent.map(&:first)).to eq(['https://push.test/other-manager'])
    expect(manager.notification_subscriptions).to be_present
  end

  it 'is sent for client messages only, not for the Evolution service chat' do
    service_contact = create(:contact, account: account, phone_number: Conversation::CRM_SERVICE_CONTACT_PHONE)
    service_message = create(:message, account: account, inbox: inbox, message_type: :incoming,
                                       conversation: create(:conversation, account: account, inbox: inbox, contact: service_contact))
    reply = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :outgoing)

    expect do
      [message, service_message, reply].each do |created|
        Custom::CrmListener.instance.message_created(Events::Base.new('message.created', Time.zone.now, message: created))
      end
    end.to have_enqueued_job(Custom::PushJob).exactly(:once).with(message)
  end

  it 'keeps Chatwoot from sending its own push' do
    manager.notification_settings.find_by(account: account).update!(selected_push_flags: [:push_conversation_creation])

    expect { create(:notification, user: manager, account: account, primary_actor: conversation, notification_type: :conversation_creation) }
      .not_to have_enqueued_job(Notification::PushNotificationJob)
  end
end
