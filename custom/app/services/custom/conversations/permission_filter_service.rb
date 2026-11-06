module Custom::Conversations::PermissionFilterService
  def perform
    super.crm_visible_to(user)
  end
end
