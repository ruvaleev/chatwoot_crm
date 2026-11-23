# Compact chat list and chat header for the new interface (crm/PRD.md, stage D): one request per screen instead of
# the full Chatwoot conversation payloads. Visibility is Chatwoot's permission filter plus our freelancer rule.
class Custom::Api::V1::Accounts::Crm::ChatsController < Api::V1::Accounts::BaseController
  FILTERS = %w[all waiting hidden].freeze
  PER_PAGE = 50

  before_action :validate_filter, only: :index
  before_action :fetch_chat, except: :index
  before_action :validate_update, only: :update

  def index
    hidden = visible_chats.where(id: hidden_ids)
    shown = visible_chats.where.not(id: hidden_ids)
    @waiting_count = shown.crm_waiting.count
    @hidden_count = hidden.count
    @chats = filtered(hidden, shown).includes(:contact, :inbox, :assignee).page(params[:page]).per(PER_PAGE)
  end

  def show; end

  def update
    @chat.update!(custom_attributes: @chat.custom_attributes.merge(update_attributes))
    render :show
  end

  def hide
    Current.user.crm_hidden_conversations.find_or_create_by!(conversation: @chat)
    head :ok
  end

  def unhide
    Current.user.crm_hidden_conversations.where(conversation: @chat).delete_all
    head :ok
  end

  private

  def visible_chats
    Conversations::PermissionFilterService.new(Current.account.conversations, Current.user, Current.account).perform
  end

  def hidden_ids
    Current.user.crm_hidden_conversations.select(:conversation_id)
  end

  def filtered(hidden, shown)
    case params.fetch(:filter, 'all')
    when 'hidden' then hidden.order(last_activity_at: :desc)
    when 'waiting' then shown.crm_waiting.order(waiting_since: :asc)
    else shown.order(last_activity_at: :desc)
    end
  end

  def fetch_chat
    @chat = visible_chats.find_by!(display_id: params[:id])
  end

  def validate_filter
    render_could_not_create_error("Unknown filter: #{params[:filter]}") unless FILTERS.include?(params.fetch(:filter, 'all'))
  end

  def validate_update
    status = update_params[:status]
    return if status.nil? || allowed_statuses.include?(status)

    render_could_not_create_error("Status not allowed: #{status}")
  end

  def allowed_statuses
    Current.user.crm_freelancer? ? Conversation::CRM_FREELANCER_STATUSES : Conversation::CRM_STATUSES
  end

  def update_params
    params.permit(:status, *Conversation::CRM_DEAL_FIELDS)
  end

  def update_attributes
    update_params.to_h.transform_keys { |key| "crm_#{key}" }
  end
end
