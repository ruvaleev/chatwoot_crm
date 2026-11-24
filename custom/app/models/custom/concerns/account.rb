# Team settings of the new interface (crm/design/brief.md, "Настройки команды"), kept in the account's
# custom_attributes. Working hours are each freelancer's own (Custom::Schedule), not the team's.
module Custom::Concerns::Account
  extend ActiveSupport::Concern

  CRM_SETTINGS_DEFAULTS = {
    'overdue_minutes' => 10,
    'overdue_minutes_off_hours' => 60,
    'notification_locale' => 'ru',
    'lost_reasons' => ['Дорого', 'Пропал', 'Не наш запрос']
  }.freeze
  CRM_LOCALES = %w[ru en].freeze
  POSITIVE_MINUTES = ->(value) { value.is_a?(Integer) && value.positive? }
  CRM_SETTINGS_RULES = {
    'overdue_minutes' => POSITIVE_MINUTES,
    'overdue_minutes_off_hours' => POSITIVE_MINUTES,
    'notification_locale' => ->(value) { CRM_LOCALES.include?(value) },
    'lost_reasons' => ->(value) { value.is_a?(Array) && value.all?(String) }
  }.freeze

  included do
    validate :crm_settings_valid, if: -> { custom_attributes.key?('crm_settings') }
  end

  def crm_settings
    CRM_SETTINGS_DEFAULTS.merge(custom_attributes.fetch('crm_settings', {}))
  end

  def crm_settings=(changes)
    self.custom_attributes = custom_attributes.merge('crm_settings' => crm_settings.merge(changes.stringify_keys.slice(*CRM_SETTINGS_DEFAULTS.keys)))
  end

  private

  def crm_settings_valid
    crm_settings.each do |key, value|
      errors.add(:crm_settings, "#{key} is invalid") unless CRM_SETTINGS_RULES.fetch(key).call(value)
    end
  end
end
