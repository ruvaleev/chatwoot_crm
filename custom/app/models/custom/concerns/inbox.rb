# Every WhatsApp number belongs to the company and is assigned to one freelancer: the freelancer who is a member of
# its inbox (freelancers are members of their own inbox only). Hand-offs go to them by default.
module Custom::Concerns::Inbox
  extend ActiveSupport::Concern

  # Evolution creates the inbox with its webhook at <evolution>/chatwoot/webhook/<instance name>.
  EVOLUTION_WEBHOOK = %r{/chatwoot/webhook/(?<instance>[^/?]+)\z}

  # A new client is first qualified by a manager: Chatwoot must not hand them to an online freelancer by itself.
  included do
    before_validation :crm_disable_auto_assignment, on: :create, if: :crm_whatsapp_instance
  end

  def crm_freelancer
    members.find(&:crm_freelancer?)
  end

  def crm_whatsapp_instance
    channel.try(:webhook_url).to_s[EVOLUTION_WEBHOOK, :instance]
  end

  # One number per freelancer and one freelancer per number; nil leaves the number unassigned.
  # The number's clients go with it to the new freelancer (for the client nothing changes: same number); a freelancer
  # leaving another number leaves its clients to the managers' "new" queue.
  def crm_assign_freelancer!(freelancer)
    transaction do
      previous = members.select(&:crm_freelancer?)
      inbox_members.where(user: previous).destroy_all
      crm_reassign_clients(previous, freelancer)
      next if freelancer.nil?

      freelancer.inbox_members.where.not(inbox: self).includes(:inbox).find_each do |membership|
        membership.inbox.crm_reassign_clients([freelancer], nil)
        membership.destroy!
      end
      inbox_members.create!(user: freelancer)
    end
  end

  def crm_reassign_clients(from, to)
    conversations.where(assignee: from).find_each { |conversation| conversation.update!(assignee: to) }
  end

  private

  def crm_disable_auto_assignment
    self.enable_auto_assignment = false
  end
end
