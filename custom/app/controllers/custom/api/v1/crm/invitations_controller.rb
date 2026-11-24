# The page behind a freelancer's sign-in link: no session yet, the token itself is the credential.
class Custom::Api::V1::Crm::InvitationsController < ActionController::API
  before_action :fetch_invitation

  def show
    render json: { name: @invitation.user.name, login: @invitation.user.crm_login }
  end

  def accept
    @invitation.accept!(params.require(:password), params.require(:password_confirmation))
    render json: { login: @invitation.user.crm_login }
  rescue ActiveRecord::RecordInvalid => e
    render json: { message: e.record.errors.full_messages.to_sentence }, status: :unprocessable_content
  end

  private

  # Unknown, used and expired links look the same.
  def fetch_invitation
    @invitation = Custom::Invitation.find_usable(params[:token].to_s)
    head :not_found if @invitation.nil?
  end
end
