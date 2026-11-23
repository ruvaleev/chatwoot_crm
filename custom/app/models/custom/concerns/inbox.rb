# Every WhatsApp number belongs to the company and is assigned to one freelancer: the freelancer who is a member of
# its inbox (freelancers are members of their own inbox only). Hand-offs go to them by default.
module Custom::Concerns::Inbox
  extend ActiveSupport::Concern

  def crm_freelancer
    members.find(&:crm_freelancer?)
  end
end
