class SponsorsController < SignaturesController
  skip_before_action :redirect_to_petition_page_if_rejected
  skip_before_action :redirect_to_petition_page_if_completed
  skip_before_action :redirect_to_petition_page_if_closed
  skip_before_action :redirect_to_petition_page_if_closed_for_signing

  before_action :block_if_not_collecting_sponsors
  before_action :redirect_to_new_sponsor_page_if_validated, only: [:verify]
  before_action :redirect_to_petition_page_if_moderated, except: [:thank_you, :signed]
  before_action :redirect_to_moderation_info_page_if_sponsored, except: [:thank_you, :signed]
  before_action :validate_creator, only: [:new]

  def verify
    unless @signature.validated?
      @signature.validate!(request: request)
    end

    store_signed_tokens_in_cookie(signed_token_hash)
    send_sponsor_support_notification_email_to_petition_owner
    redirect_to signed_sponsor_url(@signature)
  end

  private

  def retrieve_petition
    @petition = Petition.not_hidden.find(petition_id)

    if @petition.flagged?
      raise ActiveRecord::RecordNotFound, "Unable to find Petition with id: #{petition_id}"
    end

    unless @petition.sponsor_token == token_param
      raise ActiveRecord::RecordNotFound, "Unable to find Petition with sponsor token: #{token_param.inspect}"
    end
  end

  def retrieve_signature
    @signature = Signature.sponsors.find(signature_id)
    @petition = @signature.petition

    if @petition.flagged? || @petition.hidden?
      raise ActiveRecord::RecordNotFound, "Unable to find Signature with id: #{signature_id}"
    end
  end

  def build_signature
    if action_name == "new"
      @signature = @petition.sponsors.build(signature_params_for_new)
    else
      @signature = @petition.sponsors.build(signature_params_for_create)
    end
  end

  def send_email_to_petition_signer
    unless @signature.email_threshold_reached?
      if @signature.pending?
        PetitionAndEmailConfirmationForSponsorEmailJob.perform_later(@signature)
      else
        EmailDuplicateSponsorEmailJob.perform_later(@signature)
      end
    end
  end

  def send_sponsor_support_notification_email_to_petition_owner
    if @petition.collecting_sponsors? && @signature.just_validated?
      if @petition.will_reach_threshold_for_moderation?
        SponsorSignedEmailOnThresholdEmailJob.perform_later(@petition.creator, @signature)
      else
        SponsorSignedEmailBelowThresholdEmailJob.perform_later(@petition.creator, @signature)
      end
    end
  end

  def thank_you_url
    thank_you_petition_sponsors_url(@petition, token: @petition.sponsor_token)
  end

  def signed_token_failure_url
    if Site.collecting_sponsors?
      moderation_info_petition_url(@petition)
    else
      raise ActionController::RoutingError, "Not available when not collecting sponsors"
    end
  end

  def redirect_to_new_sponsor_page_if_validated
    if @signature.validated_before?(15.minutes.ago)
      redirect_to new_petition_sponsor_url(@petition, token: @petition.sponsor_token)
    end
  end

  def redirect_to_petition_page_if_moderated
    if @petition.moderated?
      redirect_to petition_url(@petition)
    end
  end

  def redirect_to_moderation_info_page_if_sponsored
    if @petition.has_maximum_sponsors?
      redirect_to moderation_info_petition_url(@petition)
    end
  end

  def validate_creator
    @petition.validate_creator!
  end

  def block_if_not_collecting_sponsors
    unless Site.collecting_sponsors?
      raise ActionController::RoutingError, "Not available when not collecting sponsors"
    end
  end
end
