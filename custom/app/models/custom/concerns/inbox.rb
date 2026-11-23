# Every WhatsApp number belongs to the company and is assigned to one freelancer: the freelancer who is a member of
# its inbox (freelancers are members of their own inbox only). Hand-offs go to them by default.
module Custom::Concerns::Inbox
  extend ActiveSupport::Concern

  # Evolution creates the inbox with its webhook at <evolution>/chatwoot/webhook/<instance name>.
  EVOLUTION_WEBHOOK = %r{/chatwoot/webhook/(?<instance>[^/?]+)\z}

  def crm_freelancer
    members.find(&:crm_freelancer?)
  end

  def crm_whatsapp_instance
    channel.try(:webhook_url).to_s[EVOLUTION_WEBHOOK, :instance]
  end

  # One number per freelancer and one freelancer per number; nil leaves the number unassigned.
  def crm_assign_freelancer!(freelancer)
    transaction do
      inbox_members.where(user: members.select(&:crm_freelancer?)).destroy_all
      next if freelancer.nil?

      InboxMember.where(user: freelancer).where.not(inbox: self).destroy_all
      inbox_members.create!(user: freelancer)
    end
  end
end
