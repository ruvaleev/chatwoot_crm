require 'rails_helper'

describe AsyncDispatcher do
  subject(:dispatcher) { described_class.new }

  let(:listener) { Custom::CrmListener.instance }
  let(:message) { create(:message) }

  it 'loads the custom extension' do
    expect(ChatwootApp.extensions).to include('custom')
    expect(described_class.ancestors).to include(Custom::AsyncDispatcher)
  end

  it 'keeps upstream listeners and adds the CRM listener' do
    expect(dispatcher.listeners).to include(listener, NotificationListener.instance)
  end

  it 'delivers message.created to the CRM listener' do
    allow(listener).to receive(:message_created)
    dispatcher.load_listeners

    dispatcher.publish_event(Events::Types::MESSAGE_CREATED, Time.zone.now, message: message)

    expect(listener).to have_received(:message_created).with(have_attributes(data: { message: message }))
  end
end
