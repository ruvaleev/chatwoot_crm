# The Chatwoot features the CRM runs with. CRM_EXTRA_FEATURES (comma-separated names from config/features.yml) turns on
# more, e.g. CRM_EXTRA_FEATURES=reports,campaigns. Accounts get exactly these flags (new ones on creation, existing ones
# with rake crm:features), and CrmDisabledFeatures answers 404 for the API and pages of the features that are off.
module Custom::Features
  # crm, chatwoot_v4 and the management pages keep Chatwoot's own interface usable in development (production doesn't
  # build it, stage L3); api_and_webhooks gates the account API on Chatwoot Cloud only.
  BASE = %w[agent_management api_and_webhooks canned_responses chatwoot_v4 crm custom_attributes inbox_management labels].freeze

  # API and pages of the features one may turn on. Plain names are /api/v1/accounts/<id>/<name>, others are paths.
  # Only their API, for Chatwoot's own interface is not in the production build: help_center pages (/hc) need the
  # portal entrypoint added to custom/config/vite_entrypoints.js.
  ROUTES = {
    'agent_bots' => %w[agent_bots],
    'assignment_v2' => %w[agent_capacity_policies assignment_policies],
    'audit_logs' => %w[audit_logs],
    'automations' => %w[automation_rules],
    'campaigns' => %w[campaigns],
    'captain_integration' => %w[captain /captain],
    'companies' => %w[companies],
    'conversation_monitors' => %w[monitors],
    'custom_roles' => %w[custom_roles],
    'data_import' => %w[data_imports],
    'help_center' => %w[portals /hc],
    'integrations' => %w[integrations dashboard_apps /linear /notion /shopify /stripe /slack_uploads],
    'macros' => %w[macros],
    'reports' => %w[reporting_events /api/v2/accounts],
    'saml' => %w[saml_settings],
    'sla' => %w[applied_slas sla_policies],
    'team_management' => %w[teams]
  }.freeze

  # Off whatever the flags say: channels other than Evolution's API inbox (they need more than a flag), outgoing
  # webhooks, CSAT surveys, the platform API, Chatwoot Cloud billing and first-run onboarding (registers with their Hub).
  ALWAYS_OFF = %w[
    branded_email_layout callbacks calls channels csat_survey_responses google instagram microsoft onboarding tiktok
    twitter webhooks whatsapp whatsapp_calls
    /webhooks /twilio /bot /google /instagram /microsoft /tiktok /twitter /widget /widget_tests /api/v1/widget /public/api
    /survey /platform/api /enterprise/api /rails/action_mailbox /installation/onboarding
  ].freeze

  # Off only for the full upstream suite, which tests Chatwoot's own features (crm/AGENTS.md).
  def self.enforced?
    ENV.fetch('CRM_BLOCK_UNUSED_FEATURES', 'true') != 'false'
  end

  def self.enabled
    extras = ENV.fetch('CRM_EXTRA_FEATURES', '').split(',').map(&:strip).compact_blank
    unknown = extras - Featurable::FEATURE_LIST.pluck('name')
    raise ArgumentError, "CRM_EXTRA_FEATURES: unknown features #{unknown.join(', ')}" if unknown.any?

    BASE | extras
  end

  def self.blocked_paths
    enabled_now = enabled
    @blocked_paths ||= {}
    @blocked_paths[enabled_now] ||= begin
      top, account = (ROUTES.except(*enabled_now).values.flatten + ALWAYS_OFF).partition { |route| route.start_with?('/') }
      %r{\A(?:/api/v1/accounts/\d+/(?:#{account.join('|')})|#{top.map { |path| Regexp.escape(path) }.join('|')})(?:[/.?]|\z)}
    end
  end
end
