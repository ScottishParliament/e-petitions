module AdminHelper
  ISO8601_TIMESTAMP = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/
  TEMPLATE_PLACEHOLDER = /\{\{([a-zA-Z][_a-zA-Z0-9]*)\}\}/

  def selected_tags
    @selected_tags ||= Array(params[:tags]).flatten.map(&:to_i).compact.reject(&:zero?)
  end

  def mandatory_field
    content_tag :span, raw(' *'), class: 'mandatory'
  end

  def cms_delete_link(model, options = {})
    options[:model_name] ||= model.name
    options[:url] ||= resource_path(model)
    link_to image_tag('admin/delete.png', :size => "16x16", :alt => "Delete"), options[:url], :data => {
                        :confirm => "WARNING: This action cannot be undone.\nAre you sure you want to delete #{h options[:model_name]}?",
                        :method => :delete
                      }
  end

  def admin_petition_facets_for_select(facets, selected)
    options = admin_petition_facets.map do |facet|
      [I18n.t(facet,  scope: :"petitions.facets.names.admin", quantity: facets[facet]), facet]
    end

    options_for_select(options, selected)
  end

  def admin_signature_states_for_select(selected)
    options_for_select(I18n.t(:states, scope: :"admin.signature"), selected)
  end

  def admin_invalidation_facets_for_select(facets, selected)
    options = admin_invalidation_facets.map do |facet|
      [I18n.t(facet,  scope: :"admin.invalidations.facets.labels", quantity: facets[facet]), facet]
    end

    options_for_select(options, selected)
  end

  def email_petitioners_with_count_submit_button(form, petition, options = {})
    i18n_options = {
      scope: :admin, count: petition.signature_count,
      formatted_count: number_with_delimiter(petition.signature_count)
    }

    html_options = {
      name: 'save_and_email', class: 'button',
      data: { confirm: t(:email_confirm, **i18n_options) }
    }.merge(options)

    form.submit(t(:email_button, **i18n_options), html_options)
  end

  def fraudulent_domains?(since: 1.hour.ago, limit: 10)
    !fraudulent_domains(since: since, limit: limit).empty?
  end

  def fraudulent_domains(since: 1.hour.ago, limit: 10)
    @fraudulent_domains ||= build_fraudulent_domains(since, limit)
  end

  def fraudulent_ips?(since: 1.hour.ago, limit: 10)
    !fraudulent_ips(since: since, limit: limit).empty?
  end

  def fraudulent_ips(since: 1.hour.ago, limit: 10)
    @fraudulent_ips ||= build_fraudulent_ips(since, limit)
  end

  def trending_domains(since: 1.hour.ago, limit: 10)
    @trending_domains ||= build_trending_domains(since, limit)
  end

  def trending_domains?(since: 1.hour.ago, limit: 10)
    !trending_domains(since: since, limit: limit).empty?
  end

  def trending_ips(since: 1.hour.ago, limit: 10)
    @trending_ips ||= build_trending_ips(since, limit)
  end

  def trending_ips?(since: 1.hour.ago, limit: 10)
    !trending_ips(since: since, limit: limit).empty?
  end

  def trending_window?
    params[:window].present? && params[:window] =~ ISO8601_TIMESTAMP
  end

  def trending_window
    if trending_window?
      starts_at = params[:window].in_time_zone
      ends_at = starts_at.advance(hours: 1)

      starts_at..ends_at
    end
  end

  def signature_count_interval_menu
    {
      "1 second" => "1",
      "2 seconds" => "2",
      "5 seconds" => "5",
      "10 seconds" => "10",
      "30 seconds" => "30",
      "1 minute" => "60",
      "5 minutes" => "300"
    }
  end

  def back_link
    if session[:back_location]
      link_to "Back", session[:back_location], class: "back-link"
    elsif @petition
      link_to "Back", admin_petitions_path, class: "back-link"
    else
      link_to "Back", admin_root_path, class: "back-link"
    end
  end

  def highlight_vars(string)
    highlight(string,  TEMPLATE_PLACEHOLDER) do |match|
      "((" + content_tag(:mark, match[2..-3]) + "))"
    end
  end

  def template_menu
    [].tap do |choices|
      choices << ["English", english_template_menu]

      unless Site.disable_gaelic_website?
        choices << ["Gaelic", gaelic_template_menu]
      end

      choices << ["Other", extra_template_menu]
    end
  end

  def existing_templates
    Notifications::Template.pluck(:name)
  end

  private

  def english_template_menu
    Notifications::Template::ENGLISH_TEMPLATES.keys.sort
  end

  def gaelic_template_menu
    Notifications::Template::GAELIC_TEMPLATES.keys.sort
  end

  def extra_template_menu
    Notifications::Template::EXTRA_TEMPLATES.keys.sort
  end

  def admin_petition_facets
    if Site.disable_thresholds_and_debates?
      I18n.t(:admin, scope: :"petitions.facets.alternate")
    else
      I18n.t(:admin, scope: :"petitions.facets")
    end
  end

  def admin_invalidation_facets
    I18n.t(:keys, scope: :"admin.invalidations.facets")
  end

  def rate_limit
    @rate_limit ||= RateLimit.first_or_create!
  end

  def build_fraudulent_domains(since, limit)
    Signature.fraudulent_domains(since: since, limit: limit)
  end

  def build_fraudulent_ips(since, limit)
    Signature.fraudulent_ips(since: since, limit: limit)
  end

  def build_trending_domains(since, limit)
    all_domains = Signature.trending_domains(since: since, limit: limit + 30)
    allowed_domains = rate_limit.allowed_domains_list

    all_domains.inject([]) do |domains, (domain, count)|
      return domains if domains.size == limit

      unless allowed_domains.any?{ |d| d === domain }
        domains << [domain, count]
      end

      domains
    end
  end

  def build_trending_ips(since, limit)
    all_ips = Signature.trending_ips(since: since, limit: limit + 30)
    allowed_ips = rate_limit.allowed_ips_list

    all_ips.inject([]) do |ips, (ip, count)|
      return ips if ips.size == limit

      unless allowed_ips.any?{ |i| i.include?(ip) }
        ips << [ip, count]
      end

      ips
    end
  end
end
