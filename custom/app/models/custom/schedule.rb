# A freelancer's working schedule (crm/design/brief.md): they set it themselves; managers see from it whether the
# number's freelancer works today, and a client waits longer before turning red outside it.
class Custom::Schedule
  TIME = /\A([01]\d|2[0-3]):[0-5]\d\z/
  RULES = {
    'time_zone' => ->(value) { ActiveSupport::TimeZone[value.to_s].present? },
    'days' => ->(value) { value.is_a?(Array) && value.all? { |day| (1..7).cover?(day) } },
    'from' => ->(value) { TIME.match?(value.to_s) },
    'to' => ->(value) { TIME.match?(value.to_s) }
  }.freeze

  def self.errors(schedule)
    return ['schedule is missing fields'] unless schedule.is_a?(Hash) && (RULES.keys - schedule.keys).empty?

    RULES.filter_map { |key, rule| "#{key} is invalid" unless rule.call(schedule[key]) }
  end
end
