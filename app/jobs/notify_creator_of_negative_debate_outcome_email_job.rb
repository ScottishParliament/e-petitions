class NotifyCreatorOfNegativeDebateOutcomeEmailJob < NotifyJob
  self.template = :notify_creator_of_negative_debate_outcome

  def perform(signature, *args)
    if signature.notify_by_email?
      super
    end
  end

  def personalisation(signature, petition, outcome)
    {
      name: signature.name,
      action_en: petition.action_en, action_gd: petition.action_gd,
      overview_en: outcome.overview_en, overview_gd: outcome.overview_gd,
      petition_url_en: petition_en_url(petition),
      petition_url_gd: petition_gd_url(petition),
      petitions_committee_url_en: help_en_url(anchor: "petitions-committee"),
      petitions_committee_url_gd: help_gd_url(anchor: "petitions-committee"),
      unsubscribe_url_en: unsubscribe_signature_en_url(signature, token: signature.unsubscribe_token),
      unsubscribe_url_gd: unsubscribe_signature_gd_url(signature, token: signature.unsubscribe_token),
    }
  end
end
