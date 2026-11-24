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
    expect(described_class.phone_like?('+1 555 01')).to be(true)
    expect(described_class.phone_like?('order 12')).to be(false)
    expect(described_class.number_probe?('77')).to be(true)
    expect(described_class.number_probe?('Anna')).to be(false)
  end

  it 'masks a number written next to the contact name' do
    expect(scrubber.scrub('name' => 'Anna +1 555 010-44-77, office')).to eq('name' => 'Anna •••77, office')
    expect(scrubber.scrub('name' => 'Room 101')).to eq('name' => 'Room 101')
  end

  it 'keeps ids that only happen to contain digits' do
    payload = { 'source_id' => 'WAID:3EB0123456789ABC', 'contact_inbox' => { 'source_id' => '8a1d2c34-5e6f-4789-a012-345678901234' } }

    expect(scrubber.scrub(payload)).to eq(payload)
    expect(scrubber.scrub('source_id' => '15550104477')).to eq('source_id' => nil)
  end
end
