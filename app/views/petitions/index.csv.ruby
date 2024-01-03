csv_builder = lambda do |csv|
  csv << ['Petition', 'URL', 'PE Number', 'Petitioner', 'Status', 'Signatures Count', 'Summary', 'Previous action', 'Background Information', 'Created At', 'Opened At', 'Under Consideration At', 'Topics']

  @petitions.find_each do |petition|
    csv << [
      csv_escape(petition.action),
      petition_url(petition),
      petition.to_param,
      petition.creator.name,
      petition.status,
      petition.signature_count,
      csv_escape(petition.background),
      csv_escape(petition.additional_details),
      csv_date_format(petition.created_at),
      csv_date_format(petition.opened_at),
      csv_date_format(petition.referred_at),
      topic_list(petition.topics)
    ]
  end
end

if @petitions.query.present?
  CSV.generate(&csv_builder)
else
  csv_cache [I18n.locale, :petitions, @petitions.scope], expires_in: 5.minutes do
    CSV.generate(&csv_builder)
  end
end
