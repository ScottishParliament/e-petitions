require 'domain_autocorrect'
require 'postcode_sanitizer'

class PetitionCreator
  extend ActiveModel::Naming
  extend ActiveModel::Translation
  include ActiveModel::Conversion

  STAGES = %w[petition replay_petition creator replay_email]

  PETITION_PARAMS     = [:action, :background, :previous_action, :additional_details]
  SIGNATURE_PARAMS    = [:name, :email, :phone_number, :address, :postcode, :location_code, :privacy_notice]
  PERMITTED_PARAMS    = [:q, :stage, :move_back, :move_next, petition_creator: PETITION_PARAMS + SIGNATURE_PARAMS]

  attr_reader :params, :errors, :request, :privacy_notice

  def initialize(params, request)
    @params = params.permit(*PERMITTED_PARAMS)
    @errors = ActiveModel::Errors.new(self)
    @request = request
  end

  def read_attribute_for_validation(attribute)
    public_send(attribute)
  end

  def to_partial_path
    "petitions/create/#{stage}_stage"
  end

  def duplicates
    Petition.current.search(q: action, count: 3).presence
  end

  def stage
    @stage ||= stage_param.in?(STAGES) ? stage_param : STAGES.first
  end

  def save
    if moving_backwards?
      @stage = previous_stage and return false
    end

    unless valid?
      return false
    end

    if done?
      @petition = Petition.new do |p|
        p.action = action
        p.background = summary
        p.previous_action = previous_action
        p.additional_details = additional_details
        p.collect_signatures = collect_signatures

        p.build_creator do |c|
          c.name = name
          c.email = email
          c.build_contact do |contact|
            contact.phone_number = phone_number
            contact.address = address
          end
          c.postcode = postcode
          c.location_code = location_code
          c.constituency_id = constituency_id
          c.notify_by_email = true
          c.ip_address = request.remote_ip
          c.privacy_notice = privacy_notice
        end
      end

      unless rate_limit.exceeded?(@petition.creator)
        @petition.save!

        if Site.collecting_sponsors?
          send_email_to_gather_sponsors(@petition)
        else
          send_email_to_validate_creator(@petition)
        end
      end

      return true
    else
      @stage = next_stage and return false
    end
  end

  def to_param
    if @petition && @petition.persisted?
      @petition.to_param
    else
      raise RuntimeError, "PetitionCreator#to_param called before petition was created"
    end
  end

  def action
    (petition_creator_params[:action] || query_param).to_s.strip
  end

  def action?
    action.present?
  end

  def background
    petition_creator_params[:background].to_s.strip
  end

  def background?
    background.present?
  end

  def summary
    background.sub(/\A(.)/) { |char| preamble + char.downcase }
  end

  def previous_action
    petition_creator_params[:previous_action].to_s.strip
  end

  def additional_details
    petition_creator_params[:additional_details].to_s.strip
  end

  def collect_signatures
    true
  end

  def name
    petition_creator_params[:name].to_s.strip
  end

  def email
    petition_creator_params[:email].to_s.strip
  end

  def email=(value)
    petition_creator_params[:email] = value
  end

  def phone_number
    petition_creator_params[:phone_number].to_s.tr('^1234567890+. ', '')
  end

  def address
    petition_creator_params[:address].to_s.strip
  end

  def postcode
    PostcodeSanitizer.call(petition_creator_params[:postcode])
  end

  def location_code
    petition_creator_params[:location_code] || "GB-SCT"
  end

  def privacy_notice
    petition_creator_params[:privacy_notice] || "0"
  end

  private

  def query_param
    @query_param ||= params[:q].to_s.first(255)
  end

  def stage_param
    @stage_param ||= params[:stage].to_s
  end

  def petition_creator_params
    params[:petition_creator] || {}
  end

  def moving_backwards?
    params.key?(:move_back)
  end

  def stage_index
    STAGES.index(stage)
  end

  def previous_stage
    STAGES[[stage_index - 1, 0].max]
  end

  def next_stage
    STAGES[[stage_index + 1, 5].min]
  end

  def validate_petition
    errors.add(:action, :invalid) if action =~ /\A[-=+@]/
    errors.add(:action, :blank) unless action.present?
    errors.add(:action, :too_long, count: 100) if action.length > 100
    errors.add(:background, :invalid) if background =~ /\A[-=+@]/
    errors.add(:background, :blank) unless background.present?
    errors.add(:background, :too_long, count: 500) if background.length > 500
    errors.add(:previous_action, :blank) unless previous_action.present?
    errors.add(:previous_action, :invalid) if previous_action =~ /\A[-=+@]/
    errors.add(:previous_action, :too_long, count: 500) if previous_action.length > 500
    errors.add(:additional_details, :blank) unless additional_details.present?
    errors.add(:additional_details, :invalid) if additional_details =~ /\A[-=+@]/
    errors.add(:additional_details, :too_long, count: 1100) if additional_details.length > 1100

    if errors.any?
      @stage = "petition"
    end
  end

  def validate_creator
    if stage == "creator"
      self.email = DomainAutocorrect.call(email)
    end

    errors.add(:name, :invalid) if name =~ /\A[-=+@]/
    errors.add(:name, :blank) unless name.present?
    errors.add(:name, :too_long, count: 255) if name.length > 255
    errors.add(:email, :blank) unless email.present?
    errors.add(:phone_number, :blank) unless phone_number.present?
    errors.add(:phone_number, :too_long, count: 31) if phone_number.length > 31
    errors.add(:location_code, :blank) unless location_code.present?
    errors.add(:address, :blank) unless address.present?
    errors.add(:address, :too_long, count: 500) if address.length > 500
    errors.add(:postcode, :too_long, count: 255) if postcode.length > 255
    errors.add(:name, :has_uri) if URI::regexp =~ name

    if email.present?
      email_validator.validate(self)
    end

    if location_code.in?(Signature::UK_COUNTRY_CODES)
      errors.add(:postcode, :blank) unless postcode.present?

      if postcode.present?
        postcode_validator.validate(self)
      end
    end

    errors.add(:privacy_notice, :accepted) unless privacy_notice == "1"

    if replay_email?
      @stage = "replay_email"
    elsif errors.any?
      @stage = "creator"
    end
  end

  def validate
    validate_petition

    if errors.empty? && reached_stage?("creator")
      validate_creator
    end
  end

  def valid?
    errors.clear
    validate
    errors.empty?
  end

  def replay_email?
    stage == "replay_email" && errors.attribute_names == [:email]
  end

  def done?
    stage == "replay_email"
  end

  def email_validator
    EmailValidator.new(attributes: [:email])
  end

  def postcode_validator
    PostcodeValidator.new(attributes: [:postcode])
  end

  def constituency
    @constituency ||= Constituency.find_by_postcode(postcode)
  end

  def constituency_id
    constituency.try(:id)
  end

  def send_email_to_gather_sponsors(petition)
    GatherSponsorsForPetitionEmailJob.perform_later(petition.creator)
  end

  def send_email_to_validate_creator(petition)
    EmailConfirmationForCreatorEmailJob.perform_later(petition.creator)
  end

  private

  def rate_limit
    @rate_limit ||= RateLimit.first_or_create!
  end

  def reached_stage?(other_stage)
    stage_index >= STAGES.index(other_stage)
  end

  def preamble
    I18n.t(:"ui.petitions.background.preamble").sub('…', ' ')
  end
end
