require 'rails_helper'

RSpec.context 'with the CRM cron schedule' do
  let(:schedule) { Sidekiq::Cron::Support.load_yaml(ERB.new(Rails.root.join('config/schedule.yml').read).result) }
  let(:housekeeping) { %w[remove_old_notification_job remove_orphan_conversations_job remove_stale_redis_keys_job.rb] }

  # Tests share Redis with development: clean up only the jobs made here.
  after { %w[trigger_imap_email_inboxes_job delete_accounts_job].each { |name| Sidekiq::Cron::Job.destroy(name) } }

  it 'registers only housekeeping from the Chatwoot schedule and removes what was registered before' do
    Sidekiq::Cron::Job.create(name: 'trigger_imap_email_inboxes_job', cron: '* * * * *', class: 'Inboxes::FetchImapEmailInboxesJob',
                              source: 'schedule')

    Sidekiq::Cron::Job.load_from_hash!(schedule, source: 'schedule')

    expect(Sidekiq::Cron::Job.all.map(&:name) & schedule.keys).to match_array(housekeeping)
  end

  it 'leaves jobs from other sources alone' do
    Sidekiq::Cron::Job.load_from_hash!(schedule.slice('delete_accounts_job'), source: 'dynamic')

    expect(Sidekiq::Cron::Job.find('delete_accounts_job')).to be_present
  end
end
