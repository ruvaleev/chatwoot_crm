require 'rails_helper'

describe Custom::PhoneScrubber do
  subject(:scrubber) { described_class.new(locale: :ru) }

  it 'removes phone numbers and WhatsApp ids wherever a contact is embedded' do
    payload = [
      { 'meta' => { 'sender' => { 'name' => 'Anna', 'phone_number' => '+15550104477', 'identifier' => '15550104477@s.whatsapp.net' } } },
      { messages: [{ sender: { name: '+1 555 010 4477', phone_number: '+15550104477' }, source_id: 'WAID:3EB0', content: 'call 15550104477' }] }
    ]

    expect(scrubber.scrub(payload)).to eq(
      [
        { 'meta' => { 'sender' => { 'name' => 'Anna', 'phone_number' => nil, 'identifier' => nil } } },
        { messages: [{ sender: { name: 'Клиент •••77', phone_number: nil }, source_id: 'WAID:3EB0', content: 'call 15550104477' }] }
      ]
    )
  end

  it 'treats queries with six or more digits as phone lookups' do
    expect(described_class.phone_like?('+66 6284')).to be(true)
    expect(described_class.phone_like?('order 12')).to be(false)
  end
end
