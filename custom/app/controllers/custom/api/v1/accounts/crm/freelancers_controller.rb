# Freelancers of the account (crm/PRD.md, stage D3): managers add them with a number and a one-time sign-in link,
# move them to another number or take their access away.
class Custom::Api::V1::Accounts::Crm::FreelancersController < Api::V1::Accounts::BaseController
  LOGIN_FORMAT = /\A[a-z0-9][a-z0-9._-]{1,30}\z/

  before_action :ensure_manager
  before_action :fetch_freelancer, except: [:index, :create]
  before_action :fetch_number, only: [:create, :update]
  before_action :validate_login, only: :create

  def index
    @freelancers = freelancers.sort_by(&:name)
    @numbers = Current.account.inboxes.includes(:channel, :members).order(:name).select(&:crm_whatsapp_instance)
  end

  def create
    user = ActiveRecord::Base.transaction do
      created = User.create!(name: params.require(:name), email: login_email, password: "#{SecureRandom.hex(16)}aA1!",
                             custom_attributes: { 'crm_freelancer' => true }, &:skip_confirmation!)
      Current.account.account_users.create!(user: created, role: :agent)
      @number&.crm_assign_freelancer!(created)
      created
    end
    render json: { id: user.id, invite_url: invite_url(user) }
  end

  def update
    current_number&.crm_assign_freelancer!(nil)
    @number&.crm_assign_freelancer!(@freelancer)
    head :ok
  end

  # A fresh link, e.g. when the old one expired or the password was forgotten.
  def invite
    render json: { invite_url: invite_url(@freelancer) }
  end

  # Chatwoot's own removal unassigns their conversations (back to "new"); open sessions end at once.
  def destroy
    ActiveRecord::Base.transaction do
      Current.account.account_users.find_by!(user: @freelancer).destroy!
      @freelancer.crm_invitations.delete_all
      @freelancer.update!(tokens: {})
    end
    head :ok
  end

  private

  def freelancers
    Current.account.users.includes(:inboxes).select(&:crm_freelancer?)
  end

  def fetch_freelancer
    @freelancer = freelancers.find { |user| user.id == params[:id].to_i } || raise(ActiveRecord::RecordNotFound)
  end

  def fetch_number
    return if params[:number_id].blank?

    @number = Current.account.inboxes.find(params[:number_id])
    raise ActiveRecord::RecordNotFound unless @number.crm_whatsapp_instance
  end

  def current_number
    @freelancer.inboxes.find_by(account: Current.account)
  end

  def validate_login
    return render_could_not_create_error('login_invalid') unless LOGIN_FORMAT.match?(params[:login].to_s)

    render_could_not_create_error('login_taken') if User.exists?(email: login_email)
  end

  def login_email
    "#{params[:login]}@#{User::CRM_LOGIN_DOMAIN}"
  end

  def invite_url(user)
    # After "#": browsers don't send it, so the token stays out of server logs.
    "#{ENV.fetch('FRONTEND_URL')}/crm/invite##{Custom::Invitation.issue!(user)}"
  end

  def ensure_manager
    head :forbidden if Current.user.crm_freelancer?
  end
end
