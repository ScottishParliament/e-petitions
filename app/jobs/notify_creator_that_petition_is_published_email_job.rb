class NotifyCreatorThatPetitionIsPublishedEmailJob < NotifyJob
  self.template = :notify_creator_that_petition_is_published

  def personalisation(signature, petition)
    {
      creator: signature.name,
      action_en:  petition.action_en, action_gd: petition.action_gd,
      url_en:  petition_en_url(petition), url_gd:  petition_gd_url(petition)
    }
  end
end
