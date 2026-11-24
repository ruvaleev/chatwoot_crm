# Freelancers (crm/PRD.md, stage 6) see only conversations currently assigned to them.
# The flag lives in custom_attributes: users can't change it themselves (ProfilesController permits only phone_number).
module Custom::Concerns::User
  extend ActiveSupport::Concern

  # Freelancers sign in with a short login; it is stored as an email on this reserved, undeliverable domain.
  CRM_LOGIN_DOMAIN = 'crm.invalid'.freeze

  included do
    validate :crm_schedule_valid, if: -> { custom_attributes.key?('crm_schedule') }
    has_many :crm_hidden_conversations, class_name: 'Custom::HiddenConversation', dependent: :delete_all
    has_many :crm_invitations, class_name: 'Custom::Invitation', dependent: :delete_all
    has_many :crm_templates, class_name: 'Custom::Template', dependent: :delete_all
  end

  def crm_login
    email.delete_suffix("@#{CRM_LOGIN_DOMAIN}")
  end

  # Nil until the freelancer sets it (Custom::Schedule).
  def crm_schedule
    custom_attributes['crm_schedule']
  end

  def crm_schedule=(schedule)
    self.custom_attributes = custom_attributes.merge('crm_schedule' => schedule)
  end

  def crm_freelancer?
    custom_attributes['crm_freelancer'] == true
  end

  private

  def crm_schedule_valid
    Custom::Schedule.errors(crm_schedule).each { |error| errors.add(:crm_schedule, error) }
  end
end
