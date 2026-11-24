# Reply templates for "/" in the composer: the team's (Chatwoot canned responses) and the user's own.
class Custom::Api::V1::Accounts::Crm::TemplatesController < Api::V1::Accounts::BaseController
  before_action :fetch_template, only: [:update, :destroy]

  def index
    render json: {
      team: Current.account.canned_responses.order(:short_code).map { |template| template.slice(:id, :short_code, :content) },
      personal: Current.user.crm_templates.order(:short_code).map { |template| template.slice(:id, :short_code, :content) }
    }
  end

  def create
    render json: Current.user.crm_templates.create!(template_params).slice(:id, :short_code, :content)
  end

  def update
    @template.update!(template_params)
    render json: @template.slice(:id, :short_code, :content)
  end

  def destroy
    @template.destroy!
    head :ok
  end

  private

  def fetch_template
    @template = Current.user.crm_templates.find(params[:id])
  end

  def template_params
    params.permit(:short_code, :content)
  end
end
