class NotifyCreatorThatPetitionWasRejectedEmailJob < NotifyJob
  self.template = :notify_creator_that_petition_was_rejected

  def personalisation(signature, petition, rejection)
    I18n.with_locale(petition.locale) do
      if insufficient_petition?
        {
          creator: signature.name,
          action_en: petition.action_en, action_gd: petition.action_gd,
          content_en: rejection.content_en, content_gd: rejection.content_gd,
          url_en: petition_en_url(petition), url_gd: petition_gd_url(petition),
          standards_url_en: help_en_url(anchor: "standards"),
          standards_url_gd: help_gd_url(anchor: "standards"),
          new_petition_url_en: check_petitions_en_url,
          new_petition_url_gd: check_petitions_gd_url
        }
      else
        {
          creator: signature.name, action: petition.action,
          content_en: rejection.content_en, content_gd: rejection.content_gd,
          url_en: petition_en_url(petition), url_gd: petition_gd_url(petition),
          standards_url_en: help_en_url(anchor: "standards"),
          standards_url_gd: help_gd_url(anchor: "standards"),
          new_petition_url_en: check_petitions_en_url,
          new_petition_url_gd: check_petitions_gd_url
        }
      end
    end
  end

  def template
    if hidden_petition?
      :"#{super}_hidden"
    elsif insufficient_petition?
      :"#{super}_insufficient"
    else
      super
    end
  end

  private

  def hidden_petition?
    arguments.first.petition.hidden?
  end

  def insufficient_petition?
    arguments.last.code == "insufficient"
  end
end
