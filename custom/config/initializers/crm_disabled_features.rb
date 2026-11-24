# The API and pages of Chatwoot features that are off (Custom::Features) answer 404 before reaching their controllers:
# account feature flags only hide them in Chatwoot's own interface, their API keeps answering.
class CrmDisabledFeatures
  def initialize(app)
    @app = app
  end

  def call(env)
    return [404, { 'content-type' => 'text/plain' }, ['Not Found']] if block?(env['PATH_INFO'])

    @app.call(env)
  end

  private

  def block?(path)
    Custom::Features.enforced? && path.match?(Custom::Features.blocked_paths)
  end
end

Rails.application.config.middleware.use CrmDisabledFeatures
