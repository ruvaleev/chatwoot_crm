# Our routes live in custom/config/routes.rb and load right after config/routes.rb (which stays untouched).
# Being a routes path, the file is reloaded in development without restarting the server.
Rails.application.config.paths['config/routes.rb'] << Rails.root.join('custom/config/routes.rb').to_s
