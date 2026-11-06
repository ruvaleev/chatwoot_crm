module Custom::Conversations::PermissionFilterService
  def perform
    user.crm_freelancer? ? super.where(assignee_id: user.id) : super
  end
end
