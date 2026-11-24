# The signed-in user's own working schedule (Custom::Schedule); managers only read freelancers' schedules.
class Custom::Api::V1::Accounts::Crm::SchedulesController < Api::V1::Accounts::BaseController
  def show
    render json: { schedule: Current.user.crm_schedule }
  end

  def update
    user = Current.user
    user.crm_schedule = params.permit(:time_zone, :from, :to, days: []).to_h
    return render_could_not_create_error(user.errors.full_messages.to_sentence) unless user.save

    render json: { schedule: user.crm_schedule }
  end
end
