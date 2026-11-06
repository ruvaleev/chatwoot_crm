# Freelancers (crm/PRD.md, stage 6) see only conversations currently assigned to them.
# The flag lives in custom_attributes: users can't change it themselves (ProfilesController permits only phone_number).
module Custom::Concerns::User
  extend ActiveSupport::Concern

  def crm_freelancer?
    custom_attributes['crm_freelancer'] == true
  end
end
