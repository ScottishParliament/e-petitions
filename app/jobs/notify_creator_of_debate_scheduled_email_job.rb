class NotifyCreatorOfDebateScheduledEmailJob < NotifyJob
  self.template = :notify_creator_of_debate_scheduled

  def perform(signature, *args)
    if signature.notify_by_email?
      super
    end
  end

  def personalisation(signature, petition)
    {
      name: signature.name,
      action_en: petition.action_en, action_gd: petition.action_gd,
      petition_url_en: petition_en_url(petition),
      petition_url_gd: petition_gd_url(petition),
      debate_date_en: short_date(petition.scheduled_debate_date, :"en-GB"),
      debate_date_gd: short_date(petition.scheduled_debate_date, :"cy-GB"),
      unsubscribe_url_en: unsubscribe_signature_en_url(signature, token: signature.unsubscribe_token),
      unsubscribe_url_gd: unsubscribe_signature_gd_url(signature, token: signature.unsubscribe_token),
    }
  end

  private

  def short_date(date, locale)
    I18n.l(date, format: "%-d %B %Y", locale: locale)
  end
end
