require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module LlgApp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2
    config.i18n.default_locale = :de
    config.active_job.queue_adapter = :delayed_job

    config.action_mailer.delivery_method = :postmark
    config.action_mailer.postmark_settings = {api_token: ENV["POSTMARK_API_TOKEN"]}

    config.autoload_paths += %W[#{Rails.root}/lib/]


    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.middleware.use OliveBranch::Middleware, inflection: 'camel', content_type_check: ->(_content_type){
      true
    }
  end
end
