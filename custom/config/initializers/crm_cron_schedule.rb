# Of Chatwoot's cron schedule (config/schedule.yml) we run only housekeeping; the rest serves features we don't use
# (mail polling, calls, campaigns, SLA, auto-resolve, version checks...). The keep/drop list is in crm/PROGRESS.md.
# Both loaders, upstream's in config/initializers/sidekiq.rb and sidekiq-cron's own at startup, call load_from_hash!,
# which also deletes from Redis the schedule entries it isn't given.
crm_cron_jobs = %w[remove_old_notification_job remove_orphan_conversations_job remove_stale_redis_keys_job.rb].freeze

Sidekiq::Cron::Job.singleton_class.prepend(Module.new do
  define_method(:load_from_hash!) do |hash, options = {}|
    super(options[:source] == 'schedule' ? hash.slice(*crm_cron_jobs) : hash, options)
  end
end)
