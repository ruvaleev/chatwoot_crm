# Serves the new interface (crm/PRD.md, stage D). The page carries no data: the app signs in and loads everything
# through the API, so nothing here depends on the old dashboard's global config.
# Like upstream's DashboardController: the page is served before sign-in, without the API auth of ApplicationController.
class Custom::CrmController < ActionController::Base # rubocop:disable Rails/ApplicationController
  layout false

  def index
    @installation_name = GlobalConfig.get_value('INSTALLATION_NAME')
  end
end
