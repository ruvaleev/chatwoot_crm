# Compact chat list and chat header for the new interface (crm/PRD.md, stage D): one request per screen instead of
# the full Chatwoot conversation payloads. Visibility is Chatwoot's permission filter plus our freelancer rule.
class Custom::Api::V1::Accounts::Crm::ChatsController < Api::V1::Accounts::BaseController
  FILTERS = %w[all waiting new mine hidden].freeze
  # Like a messenger by default; "waiting" puts the longest wait first.
  SORTS = %w[recent waiting].freeze
  PER_PAGE = 50
  DEAL_FIELD_LIMIT = 200

  before_action :validate_list_params, only: :index
  before_action :fetch_chat, except: :index
  before_action :validate_update, only: :update
  before_action :ensure_manager, :fetch_handoff_target, only: :handoff

  # Only client chats: Evolution's service chat (QR codes, connection statuses) belongs to the numbers screen.
  def index
    clients = visible_chats.crm_client_chats
    hidden = narrowed(clients.where(id: hidden_ids))
    shown = narrowed(clients.where.not(id: hidden_ids))
    @counts = tab_counts(shown).merge(hidden: hidden.count)
    @inboxes = Current.user.assigned_inboxes.order(:name)
    @chats = filtered(hidden, shown).includes({ contact: :labels }, :assignee, inbox: :members).page(params[:page]).per(PER_PAGE)
    load_rows(@chats)
  end

  def show
    @number_state = number_state
    load_rows([@chat])
  end

  def update
    @chat.update!(custom_attributes: @chat.custom_attributes.merge(update_attributes))
    load_rows([@chat])
    render :show
  end

  # The manager's brief is saved as a private note and pinned in the chat; the conversation goes to the freelancer.
  def handoff
    ActiveRecord::Base.transaction do
      brief = Messages::MessageBuilder.new(Current.user, @chat, { content: params.require(:brief), private: true }).perform
      @chat.update!(assignee: @handoff_target,
                    custom_attributes: @chat.custom_attributes.merge('crm_status' => 'handed_off', 'crm_brief_message_id' => brief.id))
    end
    load_rows([@chat])
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

  # Shown in the chat when the number is down. Evolution being unreachable must not keep the chat from opening.
  def number_state
    instance = @chat.inbox.crm_whatsapp_instance
    return if instance.nil?

    Custom::Whatsapp::EvolutionClient.new.state(instance)
  rescue StandardError => e
    Rails.logger.warn("CRM: number state of #{instance} unavailable: #{e.message}")
    'unknown'
  end

  def load_rows(chats)
    ids = chats.map(&:id)
    @last_messages = Conversation.crm_last_messages(ids)
    @unread_counts = Conversation.crm_unread_counts(ids)
  end

  def visible_chats
    Conversations::PermissionFilterService.new(Current.account.conversations, Current.user, Current.account).perform
  end

  def hidden_ids
    Current.user.crm_hidden_conversations.select(:conversation_id)
  end

  def tab_counts(shown)
    { waiting: shown.crm_waiting.count, new: shown.where(assignee_id: nil).count, mine: shown.where(assignee_id: Current.user.id).count }
  end

  # Number, status and search apply to every tab and to the counters.
  def narrowed(chats)
    chats = chats.where(inbox_id: params[:inbox_id]) if params[:inbox_id].present?
    chats = chats.crm_with_status(params[:status]) if params[:status].present?
    params[:q].present? ? searched(chats, params[:q].strip) : chats
  end

  # Freelancers can't look a client up by phone: with any digit in the query they search message text only,
  # otherwise a few digits at a time would confirm a number they are not shown.
  def searched(chats, query)
    freelancer = Current.user.crm_freelancer?
    chats.crm_matching(query, contacts: !(freelancer && Custom::PhoneScrubber.number_probe?(query)), phone: !freelancer)
  end

  def filtered(hidden, shown)
    chats = case params.fetch(:filter, 'all')
            when 'hidden' then hidden
            when 'waiting' then shown.crm_waiting
            when 'new' then shown.where(assignee_id: nil)
            when 'mine' then shown.where(assignee_id: Current.user.id)
            else shown
            end
    chats.order(sort_order)
  end

  def sort_order
    recent = Conversation.arel_table[:last_activity_at].desc
    params.fetch(:sort, 'recent') == 'waiting' ? [Conversation.arel_table[:waiting_since].asc.nulls_last, recent] : recent
  end

  def fetch_chat
    @chat = visible_chats.find_by!(display_id: params[:id])
  end

  def validate_list_params
    return render_could_not_create_error("Unknown filter: #{params[:filter]}") unless FILTERS.include?(params.fetch(:filter, 'all'))
    return render_could_not_create_error("Unknown sort: #{params[:sort]}") unless SORTS.include?(params.fetch(:sort, 'recent'))
    return if params[:status].blank? || Conversation::CRM_STATUSES.include?(params[:status])

    render_could_not_create_error("Unknown status: #{params[:status]}")
  end

  # Errors the interface shows are codes; their texts live in its RU/EN dictionaries.
  def validate_update
    status = update_params[:status]
    return render_could_not_create_error('status_not_allowed') unless status.nil? || allowed_statuses.include?(status)

    too_long = Conversation::CRM_DEAL_FIELDS.any? { |field| update_params[field].to_s.length > DEAL_FIELD_LIMIT }
    render_could_not_create_error('deal_field_too_long') if too_long
  end

  def ensure_manager
    head :forbidden if Current.user.crm_freelancer?
  end

  # By default the freelancer the number is assigned to; otherwise someone with access to the number's inbox.
  def fetch_handoff_target
    @handoff_target = params[:assignee_id].present? ? @chat.inbox.members.find_by(id: params[:assignee_id]) : @chat.inbox.crm_freelancer
    render_could_not_create_error('no_freelancer') if @handoff_target.nil?
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
