require 'shoryuken'

module Notifications
  class Worker
    include Shoryuken::Worker

    shoryuken_options body_parser: Event

    def perform(message, event)
      if Notification.process!(event)
        message.delete
      end
    end
  end
end
