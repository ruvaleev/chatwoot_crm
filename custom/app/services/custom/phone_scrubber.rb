# Removes client phone numbers from JSON payloads sent to freelancers (crm/PRD.md, stage 6).
# Key-based, so it covers contacts wherever they are embedded: conversation meta, message senders, notifications.
class Custom::PhoneScrubber
  MASK = '•••'.freeze
  # Evolution API stores the WhatsApp JID (<phone>@s.whatsapp.net) as the contact identifier.
  PHONE_LIKE_KEYS = %w[identifier source_id].freeze
  MIN_PHONE_DIGITS = 6

  pattr_initialize [:locale!]

  def self.phone_like?(text)
    text.to_s.count('0-9') >= MIN_PHONE_DIGITS
  end

  def scrub(value)
    case value
    when Hash then value.each_with_object(value.class.new) { |(key, item), result| result[key] = scrub_pair(key.to_s, item) }
    when Array then value.map { |item| scrub(item) }
    else value
    end
  end

  private

  def scrub_pair(key, value)
    return nil if key == 'phone_number'
    return nil if PHONE_LIKE_KEYS.include?(key) && value.to_s.match?(/\d{#{MIN_PHONE_DIGITS}}/o)
    # WhatsApp contacts without a profile name are named after their number.
    return masked_name(value) if key == 'name' && value.to_s.match?(/\A[+\d\s\-().]+\z/) && self.class.phone_like?(value)

    scrub(value)
  end

  def masked_name(name)
    I18n.t('crm.contact.masked_name', last_digits: name.delete('^0-9').last(2), locale: locale)
  end
end
