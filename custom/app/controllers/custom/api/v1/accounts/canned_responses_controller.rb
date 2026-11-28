# Team templates are the manager's: freelancers use them but don't change them (their own are Custom::Template).
module Custom::Api::V1::Accounts::CannedResponsesController
  def self.prepended(base)
    base.before_action :crm_forbid_freelancers, only: [:create, :update, :destroy]
  end

  private

  def crm_forbid_freelancers
    head :forbidden if Current.user.crm_freelancer?
  end
end
