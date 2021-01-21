class EmailDuplicateSignaturesEmailJob < NotifyJob
  self.template = :email_duplicate_signatures

  def perform(signature)
    super && increment_counter(signature)
  end

  def personalisation(signature, petition)
    {
      action_en:  petition.action_en, action_gd: petition.action_gd,
      url_en:  petition_en_url(petition), url_gd:  petition_gd_url(petition)
    }
  end

  private

  def increment_counter(signature)
    Signature.increment_counter(:email_count, signature.id)
  end
end
