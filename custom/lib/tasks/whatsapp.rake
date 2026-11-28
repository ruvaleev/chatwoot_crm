namespace :crm do
  namespace :whatsapp do
    desc 'Link a WhatsApp number via Evolution API: crm:whatsapp:connect[instance_name,inbox_name,account_id]'
    task :connect, [:instance_name, :inbox_name, :account_id] => :environment do |_task, args|
      account = args[:account_id] ? Account.find(args[:account_id]) : Account.sole
      instance_name = args.fetch(:instance_name)
      result = Custom::Whatsapp::ConnectService.new(account: account, instance_name: instance_name,
                                                    inbox_name: args[:inbox_name] || instance_name).perform

      if result.dig('instance', 'state') == 'open'
        puts "#{instance_name}: already connected"
      else
        puts "#{instance_name}: scan the QR code in Chatwoot → inbox \"#{args[:inbox_name] || instance_name}\" → " \
             'conversation with "WhatsApp" (WhatsApp on the phone → Linked devices → Link a device)'
      end
    end
  end
end
