require 'rails_helper'

describe ActionCableListener do
  let(:listener) { described_class.instance }
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let!(:admin) { create(:user, account: account, role: :administrator) }
  let!(:freelancer) { create(:user, account: account, role: :agent, custom_attributes: { crm_freelancer: true }) }
  let!(:manager) { create(:user, account: account, role: :agent) }

  before do
    create(:inbox_member, inbox: inbox, user: freelancer)
    create(:inbox_member, inbox: inbox, user: manager)
    allow(ActionCableBroadcastJob).to receive(:perform_later)
  end

  it 'does not send messages of other conversations to the freelancer' do
    message = create(:message, account: account, inbox: inbox, conversation: create(:conversation, account: account, inbox: inbox, assignee: manager))

    listener.message_created(Events::Base.new('message.created', Time.zone.now, message: message))

    expect(ActionCableBroadcastJob).to have_received(:perform_later)
      .with(a_collection_containing_exactly(admin.pubsub_token, manager.pubsub_token, message.conversation.contact_inbox.pubsub_token),
            'message.created', anything).at_least(:once)
  end

  it 'sends messages of the assigned conversation to the freelancer' do
    message = create(:message, account: account, inbox: inbox,
                               conversation: create(:conversation, account: account, inbox: inbox, assignee: freelancer))

    listener.message_created(Events::Base.new('message.created', Time.zone.now, message: message))

    expect(ActionCableBroadcastJob).to have_received(:perform_later).with(include(freelancer.pubsub_token), 'message.created',
                                                                          anything).at_least(:once)
  end

  it 'hides typing in other conversations from the freelancer' do
    conversation = create(:conversation, account: account, inbox: inbox)

    listener.conversation_typing_on(Events::Base.new('conversation.typing_on', Time.zone.now, conversation: conversation, user: manager))

    expect(ActionCableBroadcastJob).to have_received(:perform_later)
      .with(array_excluding(freelancer.pubsub_token), 'conversation.typing_on', anything)
  end

  it 'sends contact events to everyone except freelancers instead of the account stream' do
    contact = create(:contact, account: account)

    listener.contact_updated(Events::Base.new('contact.updated', Time.zone.now, contact: contact))

    expect(ActionCableBroadcastJob).to have_received(:perform_later)
      .with(a_collection_containing_exactly(admin.pubsub_token, manager.pubsub_token), 'contact.updated', anything)
  end

  it 'sends the freelancer a copy of the event without client phone numbers' do
    conversation = create(:conversation, account: account, inbox: inbox, assignee: freelancer)
    conversation.contact.update!(phone_number: '+15550104477')

    listener.conversation_updated(Events::Base.new('conversation.updated', Time.zone.now, conversation: conversation))

    expect(ActionCableBroadcastJob).to have_received(:perform_later)
      .with([freelancer.pubsub_token], 'conversation.updated', hash_including(meta: hash_including(sender: hash_including(phone_number: nil))))
    expect(ActionCableBroadcastJob).to have_received(:perform_later)
      .with(array_excluding(freelancer.pubsub_token), 'conversation.updated',
            hash_including(meta: hash_including(sender: hash_including(phone_number: '+15550104477'))))
  end

  it 'tells the freelancer to drop a conversation reassigned to someone else' do
    conversation = create(:conversation, account: account, inbox: inbox, assignee: freelancer)
    conversation.update!(assignee: manager)

    expect(ActionCableBroadcastJob).to have_received(:perform_later)
      .with([freelancer.pubsub_token], 'conversation.crm_access_revoked', hash_including(id: conversation.display_id))
  end

  it 'does not revoke anything from agents who keep seeing the conversation' do
    conversation = create(:conversation, account: account, inbox: inbox, assignee: manager)
    conversation.update!(assignee: freelancer)

    expect(ActionCableBroadcastJob).not_to have_received(:perform_later).with(anything, 'conversation.crm_access_revoked', anything)
  end
end
