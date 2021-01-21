class NotifySignerOfPositiveDebateOutcomeEmailJob < NotifyJob
  self.template = :notify_signer_of_positive_debate_outcome

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
      transcript_url_en: outcome.transcript_url_en, transcript_url_gd: outcome.transcript_url_gd,
      video_url_en: outcome.video_url_en, video_url_gd: outcome.video_url_gd,
      debate_pack_url_en: outcome.debate_pack_url_en, debate_pack_url_gd: outcome.debate_pack_url_gd,
      petition_url_en: petition_en_url(petition), petition_url_gd: petition_gd_url(petition),
      unsubscribe_url_en: unsubscribe_signature_en_url(signature, token: signature.unsubscribe_token),
      unsubscribe_url_gd: unsubscribe_signature_gd_url(signature, token: signature.unsubscribe_token),
    }
  end
end
