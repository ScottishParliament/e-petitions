csv_builder = lambda do |csv|
  csv << ['Petition', 'URL', 'PE Number', 'Petitioner', 'Status', 'Signatures Count', 'Summary', 'Previous action', 'Background Information']

  @petitions.find_each do |petition|
    csv << [
      csv_escape(petition.action),
      petition_url(petition),
      petition.to_param,
      petition.creator.name,
      petition.status,
      petition.signature_count,
      csv_escape(petition.background),
      csv_escape(petition.previous_action),
      csv_escape(petition.additional_details)
    ]
  end
end

if @petitions.query.present?
  CSV.generate(&csv_builder)
else
  csv_cache [:petitions, @petitions.scope], expires_in: 5.minutes do
    CSV.generate(&csv_builder)
  end
end
