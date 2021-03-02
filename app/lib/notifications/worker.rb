require 'shoryuken'

module Notifications
  class Worker
    include Shoryuken::Worker

    shoryuken_options body_parser: Event

    def perform(message, event)
      Appsignal.set_namespace("mailer")

      if Notification.process!(event)
        message.delete
      end
    end
  end
end
