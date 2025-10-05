Rails.application.config.to_prepare do
  # Tell Delayed::Web that we're using ActiveRecord as our backend.
  Delayed::Web::Job.backend = 'active_record'

  # Authenticate our delayed job web interface
  Delayed::Web::ApplicationController.class_eval do
    include Authentication, FlashI18n

    def admin_request?
      true
    end

    protected

    def admin_login_url
      main_app.admin_login_url
    end
  end
end
