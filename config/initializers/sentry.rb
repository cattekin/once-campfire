ActiveSupport.on_load(:action_cable_connection) do
  # Rails now calls these callbacks through Server::Socket. Sentry still
  # wraps them as private methods, preventing WebSocket connections from opening.
  Sentry::Rails::ActionCableExtensions::Connection.module_eval do
    public :handle_open, :handle_close
  end
end

if Rails.env.production? && ENV["SKIP_TELEMETRY"].blank?
  Sentry.init do |config|
    config.dsn = ENV["SENTRY_DSN"]
    config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]
    config.send_default_pii = false
    config.release = ENV["GIT_REVISION"]
  end
end
