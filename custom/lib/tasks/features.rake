namespace :crm do
  desc 'Give every account the CRM features (Custom::Features, CRM_EXTRA_FEATURES); rerun after changing CRM_EXTRA_FEATURES'
  task features: :environment do
    Account.find_each do |account|
      account.crm_limit_features!
      puts "#{account.name}: on — #{account.enabled_features.keys.join(', ')}"
    end
  end
end
