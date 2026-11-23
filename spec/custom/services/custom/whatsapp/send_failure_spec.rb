require 'rails_helper'

describe Custom::Whatsapp::SendFailure do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:agent) { create(:user, account: account) }
  let(:bridge) { create(:user, account: account, email: Custom::Whatsapp::ConnectService::BRIDGE_EMAIL) }
  let!(:sent) { create(:message, conversation: conversation, account: account, inbox: inbox, message_type: :outgoing, sender: agent, status: :sent) }
  let(:note_attributes) { { conversation: conversation, account: account, inbox: inbox, message_type: :outgoing, private: true } }
  let(:failure_note) { create(:message, **note_attributes, sender: bridge, content: '🚨 The message could not be sent. _1006_') }
  let(:listener) { Custom::CrmListener.instance }

  it 'marks the latest outgoing message as failed and drops the note' do
    listener.message_created(Events::Base.new('message.created', Time.zone.now, message: failure_note))

    expect(sent.reload).to have_attributes(status: 'failed', external_error: include('1006'))
    expect(Message.exists?(failure_note.id)).to be(false)
  end

  it 'leaves notes of people and other bridge notes alone' do
    people_note = create(:message, **note_attributes, sender: agent, content: '🚨 urgent client')
    qr_note = create(:message, **note_attributes, sender: bridge, content: 'QR code updated')

    [people_note, qr_note].each { |note| listener.message_created(Events::Base.new('message.created', Time.zone.now, message: note)) }

    expect(sent.reload.status).to eq('sent')
    expect(Message.where(id: [people_note.id, qr_note.id]).count).to eq(2)
  end

  it 'does not blame a message sent long before' do
    sent.update!(created_at: 10.minutes.ago)

    listener.message_created(Events::Base.new('message.created', Time.zone.now, message: failure_note))

    expect(sent.reload.status).to eq('sent')
    expect(Message.exists?(failure_note.id)).to be(true)
  end
end
