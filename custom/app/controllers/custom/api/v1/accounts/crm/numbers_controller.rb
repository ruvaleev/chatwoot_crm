# The company's WhatsApp numbers (crm/PRD.md, stage D3): managers connect them by QR code and assign each to a
# freelancer. A number is an API inbox whose webhook points at an Evolution instance.
class Custom::Api::V1::Accounts::Crm::NumbersController < Api::V1::Accounts::BaseController
  before_action :ensure_manager
  before_action :fetch_number, except: [:index, :create]
  before_action :fetch_freelancer, only: :update

  def index
    states = evolution.instances.index_by { |instance| instance['name'] }
    @numbers = numbers.map { |inbox| [inbox, states[inbox.crm_whatsapp_instance]] }
    @freelancers = Current.account.users.select(&:crm_freelancer?).sort_by(&:name)
  end

  # A new number only by an explicit manager action: Evolution creates its inbox and returns the QR code.
  def create
    instance = "crm-#{SecureRandom.alphanumeric(10).downcase}"
    render json: qr_payload(instance, Custom::Whatsapp::ConnectService.new(account: Current.account, instance_name: instance,
                                                                           inbox_name: params.require(:name)).perform)
  end

  def connect
    render json: qr_payload(@instance, evolution.connect(@instance))
  end

  def state
    render json: { state: evolution.state(@instance) }
  end

  def update
    @number.crm_assign_freelancer!(@freelancer)
    head :ok
  end

  def restart
    evolution.restart(@instance)
    head :ok
  end

  def logout
    evolution.logout(@instance)
    head :ok
  end

  private

  def evolution
    @evolution ||= Custom::Whatsapp::EvolutionClient.new
  end

  def numbers
    Current.account.inboxes.includes(:channel, :members).order(:name).select(&:crm_whatsapp_instance)
  end

  def fetch_number
    @number = numbers.find { |inbox| inbox.id == params[:id].to_i } || raise(ActiveRecord::RecordNotFound)
    @instance = @number.crm_whatsapp_instance
  end

  def fetch_freelancer
    return if params[:freelancer_id].blank?

    @freelancer = Current.account.users.find(params[:freelancer_id])
    render_could_not_create_error('Not a freelancer') unless @freelancer.crm_freelancer?
  end

  def ensure_manager
    head :forbidden if Current.user.crm_freelancer?
  end

  def qr_payload(instance, connection)
    { instance: instance, state: connection.dig('instance', 'state'), qr: connection['base64'] }
  end
end
