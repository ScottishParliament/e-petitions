class EmailConfirmationForSignerEmailJob < NotifyJob
  self.template = :email_confirmation_for_signer

  include RateLimiting

  def personalisation(signature, petition)
    {
      action_en:  petition.action_en, action_gd: petition.action_gd,
      url_en:  verify_signature_en_url(signature, token: signature.perishable_token),
      url_gd:  verify_signature_gd_url(signature, token: signature.perishable_token)
    }
  end
end
