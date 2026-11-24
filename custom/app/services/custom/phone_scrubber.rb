# Removes client phone numbers from JSON payloads sent to freelancers (crm/PRD.md, stage 6).
# Key-based, so it covers contacts wherever they are embedded: conversation meta, message senders, notifications.
class Custom::PhoneScrubber
  MASK = '•••'.freeze
  # Evolution API stores the WhatsApp JID (<phone>@s.whatsapp.net) as the contact identifier.
  PHONE_LIKE_KEYS = %w[identifier source_id].freeze
  MIN_PHONE_DIGITS = 6
  # A number or a WhatsApp JID (<phone>@s.whatsapp.net). Message ids (WAID:<hex>) and UUIDs don't match.
  PHONE_ID = /\A\+?[\d\s\-().]+(@[\w.]+)?\z/
  PHONE_NUMBER = /\A[+\d\s\-().]+\z/
  PHONE_IN_TEXT = /\+?\d[\d\s\-().]*\d/

  pattr_initialize [:locale!]

  def self.phone_like?(text)
    text.to_s.count('0-9') >= MIN_PHONE_DIGITS
  end

  # Searches for a freelancer: any digit in the query could probe part of a client's number (a name made of the
  # number, the phone, the WhatsApp id), and a few digits at a time add up to the whole number.
  def self.number_probe?(text)
    text.to_s.match?(/\d/)
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
    return nil if PHONE_LIKE_KEYS.include?(key) && value.to_s.match?(PHONE_ID) && self.class.phone_like?(value)
    return scrub_name(value) if key == 'name' && value.is_a?(String)

    scrub(value)
  end

  # WhatsApp contacts without a profile name are named after their number; others may carry it next to the name.
  def scrub_name(name)
    return name unless self.class.phone_like?(name)
    return I18n.t('crm.contact.masked_name', last_digits: last_digits(name), locale: locale) if name.match?(PHONE_NUMBER)

    name.gsub(PHONE_IN_TEXT) { |number| self.class.phone_like?(number) ? "#{MASK}#{last_digits(number)}" : number }
  end

  def last_digits(number)
    number.delete('^0-9').last(2)
  end
end
