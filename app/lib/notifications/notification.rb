require 'aws-sdk-sesv2'
require 'textacular/searchable'

module Notifications
  class Notification < ActiveRecord::Base
    extend Searchable(:to, :reference)
    include Browseable

    self.default_page_size = 10

    facet :all, -> { by_latest }

    enum :status, {
      created:    0,
      sending:    1,
      delivered:  2,
      bounced:    3,
      rejected:   4,
      complained: 5,
      failed:     6
    }

    FAILURES = %w[bounced rejected complained failed]
    PLACEHOLDER = /\(\(([a-zA-Z][_a-zA-Z0-9]*)\)\)/
    UUID = /\A[a-f0-9]{8}(?:-[a-f0-9]{4}){3}-[a-f0-9]{12}\z/

    VALID_KEYS = %i[
      email_address
      template_id
      reference
      personalisation
    ]

    validates :to, presence: true, email: true
    validates :template_id, presence: true, format: { with: UUID }
    validates :reference, presence: true, length: { maximum: 100 }

    delegate :name, to: :template, prefix: true

    belongs_to :template, optional: true

    before_validation do
      self.personalisation ||= {}
    end

    before_save do
      if failure.present?
        self.status = :failed
      elsif reject.present?
        self.status = :rejected
      elsif complaint.present?
        self.status = :complained
      elsif bounce.present?
        self.status = :bounced
      elsif delivery.present?
        self.status = :delivered
      else
        self.status = :sending
      end
    end

    alias_attribute :email_address, :to

    store_accessor :events, :delivery
    store_accessor :events, :bounce
    store_accessor :events, :complaint
    store_accessor :events, :reject
    store_accessor :events, :failure

    class << self
      def by_latest
        preload(:template).order(created_at: :desc)
      end

      def send!(options)
        options.assert_valid_keys(*VALID_KEYS)

        transaction do
          notification = create!(options)

          client = Aws::SESV2::Client.new
          response = client.send_email(notification.payload)

          if response.successful?
            notification.update!(message_id: response.message_id)
          end
        end
      end

      def process!(event)
        notification = find_by!(message_id: event.message_id)
        notification.update!(event.type => event.payload)
      end

      def cleanup!(time)
        where(arel_table[:created_at].lt(time)).delete_all
      end
    end

    def subject
      return unless template.present?

      template.subject.dup.tap do |subject|
        personalisation.each do |key, value|
          subject.gsub!("((#{key}))", value.to_s)
        end
      end
    end

    def body
      return unless template.present?

      body = template.body.dup

      personalisation.each do |key, value|
        body.gsub!("((#{key}))", value.to_s)
      end

      view = TemplateView.new(body: body)
      view.render(inline: "<%= markdown_to_html(@body) %>")
    end

    def timestamp
      case status
      when "sending"
        created_at
      when "delivered"
        delivery["timestamp"].in_time_zone
      when "bounced"
        bounce["timestamp"].in_time_zone
      when "rejected"
        reject["timestamp"].in_time_zone
      when "complained"
        complaint["timestamp"].in_time_zone
      when "failed"
        failure["timestamp"].in_time_zone
      end
    end

    def message
      case status
      when "sending"
        timestamp.strftime("Sending since %-d %B at %-I:%M%P")
      when "delivered"
        timestamp.strftime("Delivered %-d %B at %-I:%M%P")
      else
        timestamp.strftime("%-d %B at %-I:%M%P")
      end
    end

    def failure?
      status.in?(FAILURES)
    end

    def error
      case status
      when "bounced"
        I18n.t bounce["bounceSubType"], scope: "admin.ses.bounced.#{bounce['bounceType']}"
      when "complained"
        I18n.t "complained", scope: "admin.ses"
      when "rejected"
        I18n.t "rejected", scope: "admin.ses"
      when "failed"
        I18n.t "failed", scope: "admin.ses"
      end
    end

    def payload
      {
        from_email_address: Site.email_from,
        destination: { to_addresses: [to] },
        configuration_set_name: configuration_set,
        content: { template: {
          template_name: template_id_for_ses,
          template_data: personalisation.to_json
        }},
        email_tags: [
          { name: "reference", value: reference },
          { name: "notification_id", value: id }
        ]
      }
    end

    def resend!
      transaction do
        client = Aws::SESV2::Client.new
        response = client.send_email(payload)

        if response.successful?
          update!(message_id: response.message_id, events: {})
        end
      end
    end

    def forward!(recipient)
      client = Aws::SESV2::Client.new

      preview = client.test_render_email_template({
        template_name: template_id_for_ses,
        template_data: personalisation.to_json
      })

      unless preview.successful?
        raise RuntimeError, "Unable to render email template '#{template_id_for_ses}'"
      end

      response = client.send_email(
        from_email_address: Site.email_from,
        destination: { to_addresses: [recipient] },
        content: { raw: { data: preview.rendered_template } }
      )

      response.successful?
    end

    def to_partial_path
      "admin/notifications/notification"
    end

    private

    def configuration_set
      ENV.fetch("EMAIL_CONFIG")
    rescue KeyError => e
      raise Client::NotConfiguredError, "Email configuration set not found"
    end

    def template_id_for_ses
      "%s-%s" % [Site.env, template_id]
    end
  end
end
