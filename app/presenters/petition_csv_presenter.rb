require 'csv'

class PetitionCSVPresenter
  include CsvHelper
  include DateTimeHelper
  include Rails.application.routes.url_helpers

  def self.fields
    urls + [:pp_number, :pe_number] + attributes + timestamps + [:notes]
  end

  def initialize(petition)
    @petition = petition
  end

  def to_csv
    CSV::Row.new(self.class.fields, values).to_s
  end

  attr_reader :petition

  private

  def self.urls
    [:public_url, :admin_url]
  end

  def self.attributes
    if Site.disable_thresholds_and_debates?
      [
        :action, :summary, :previous_action, :additional_details, :status,
        :creator_name, :creator_email, :signature_count, :rejection_code, :rejection_details
      ]
    else
      [
        :action, :summary, :previous_action, :additional_details, :status,
        :creator_name, :creator_email, :signature_count, :rejection_code, :rejection_details,
        :debate_date, :debate_transcript_url, :debate_video_url, :debate_pack_url, :debate_overview
      ]
    end
  end

  def self.timestamps
    if Site.disable_thresholds_and_debates?
      [
        :created_at, :updated_at, :open_at, :under_consideration_at, :closed_at, :rejected_at
      ]
    else
      [
        :created_at, :updated_at, :open_at, :under_consideration_at, :closed_at, :scheduled_debate_date,
        :referral_threshold_reached_at, :debate_threshold_reached_at, :rejected_at,
        :debate_outcome_at, :moderation_threshold_reached_at
      ]
    end
  end

  def values
    self.class.fields.map {|field| send field }
  end

  def public_url
    petition_url @petition
  end

  def admin_url
    admin_petition_url @petition
  end

  def notes
    petition.note.details if petition.note
  end

  def pp_number
    csv_escape('PP%04d' % petition.id)
  end

  def pe_number
    csv_escape(petition.pe_number_id? ? 'PE%04d' % petition.pe_number_id : nil)
  end

  attributes.each do |attribute|
    case attribute
    when :summary
      class_eval <<~RUBY
        def summary
          csv_escape petition.send(:background)
        end
      RUBY
    else
      define_method attribute do
        csv_escape petition.send attribute
      end
    end
  end

  timestamps.each do |timestamp|
    case timestamp
    when :under_consideration_at
      class_eval <<~RUBY
        def under_consideration_at
          api_date_format petition.send :closed_at
        end
      RUBY
    when :closed_at
      class_eval <<~RUBY
        def closed_at
          api_date_format petition.send :completed_at
        end
      RUBY
    else
      define_method timestamp do
        api_date_format petition.send timestamp
      end
    end
  end
end
