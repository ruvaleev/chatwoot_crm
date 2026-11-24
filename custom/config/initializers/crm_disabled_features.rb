# The API and pages of Chatwoot features that are off (Custom::Features) answer 404 before reaching their controllers:
# account feature flags only hide them in Chatwoot's own interface, their API keeps answering.
class CrmDisabledFeatures
  def initialize(app)
    @app = app
  end

  def call(env)
    # The router squeezes repeated slashes (//hc, /api//v1/widget), so the path is checked the way it will be routed.
    path = ActionDispatch::Journey::Router::Utils.normalize_path(env['PATH_INFO'])
    return [404, { 'content-type' => 'text/plain' }, ['Not Found']] if block?(path)

    @app.call(env)
  end

  private

  def block?(path)
    Custom::Features.enforced? && path.match?(Custom::Features.blocked_paths)
  end
end

Rails.application.config.middleware.use CrmDisabledFeatures
