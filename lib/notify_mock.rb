require "rails-html-sanitizer"

module NotifyMock
  URL = "https://email.eu-west-2.amazonaws.com/v2/email/outbound-emails"

  APPLICATION = Module.new do
    class << self
      include MarkdownHelper

      def call(env)
        params = JSON.parse(env["rack.input"].read)
        name = params.dig("Content", "Template", "TemplateName")
        template = templates.fetch(name.to_s.split("-", 2).last)
        personalisation = JSON.parse(params.dig("Content", "Template", "TemplateData"))

        message = Mail::Message.new
        subject = template["subject"].dup
        body    = template["body"].dup

        personalisation.each do |key, value|
          subject.gsub!("((#{key}))", value.to_s)
          body.gsub!("((#{key}))", value.to_s)
        end

        text_part = markdown_to_text(body)
        html_part = markdown_to_html(body)

        message.message_id = "#{SecureRandom.uuid}@#{Site.host}"
        message.from = Site.email_from
        message.to = params.dig("Destination", "ToAddresses").first
        message.subject = subject
        message.text_part = text_part
        message.html_part = html_part

        ActionMailer::Base.deliveries << message

        [ 200, { "content-type" => "application/json" }, ["{}"] ]
      end

      def sanitize(html, options = {})
        safe_list_sanitizer.sanitize(html, options)&.html_safe
      end

      private

      def templates
        @templates ||= load_templates
      end

      def load_templates
        template_files.each_with_object({}) do |file, hash|
          hash[File.basename(file, ".yml")] = YAML.load_file(file)
        end
      end

      def template_files
        Dir["#{template_dir}/*.yml"]
      end

      def template_dir
        Rails.root.join("spec", "fixtures", "notify")
      end

      def sanitizer_vendor
        Rails::Html::Sanitizer
      end

      def safe_list_sanitizer
        @safe_list_sanitizer ||= sanitizer_vendor.safe_list_sanitizer.new
      end
    end
  end

  class << self
    def url
      URL
    end

    def app
      APPLICATION
    end
  end
end
