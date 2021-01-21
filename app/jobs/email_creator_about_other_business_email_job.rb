class EmailCreatorAboutOtherBusinessEmailJob < NotifyJob
  self.template = :email_creator_about_other_business

  def perform(signature, *args)
    if signature.notify_by_email?
      super
    end
  end

  def personalisation(signature, petition, email)
    {
      name: signature.name,
      action_en: petition.action_en, action_gd: petition.action_gd,
      petition_url_en: petition_en_url(petition),
      petition_url_gd: petition_gd_url(petition),
      subject_en: email.subject_en, subject_gd: email.subject_gd,
      body_en: email.body_en, body_gd: email.body_gd,
      unsubscribe_url_en: unsubscribe_signature_en_url(signature, token: signature.unsubscribe_token),
      unsubscribe_url_gd: unsubscribe_signature_gd_url(signature, token: signature.unsubscribe_token),
    }
  end
end
