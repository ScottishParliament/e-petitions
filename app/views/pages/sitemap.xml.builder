xml.instruct! :xml, version: "1.0"
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  xml.url do
    xml.loc home_url
    xml.changefreq "daily"
    xml.priority "1.0"
  end

  xml.url do
    xml.loc contact_url
    xml.changefreq "monthly"
    xml.priority "1.0"
  end

  xml.url do
    xml.loc help_url
    xml.changefreq "monthly"
    xml.priority "1.0"
  end

  xml.url do
    xml.loc privacy_url
    xml.changefreq "monthly"
    xml.priority "1.0"
  end

  xml.url do
    xml.loc rules_url
    xml.changefreq "monthly"
    xml.priority "1.0"
  end

  xml.url do
    xml.loc accessibility_url
    xml.changefreq "monthly"
    xml.priority "1.0"
  end

  xml.url do
    xml.loc check_petitions_url
    xml.changefreq "monthly"
    xml.priority "1.0"
  end

  xml.url do
    xml.loc petitions_url
    xml.changefreq "daily"
    xml.priority "0.8"
  end

  Petition.sitemap.each do |petition|
    xml.url do
      xml.loc petition_url(petition)
      xml.changefreq petition.open? ? "daily" : "weekly"
      xml.priority petition.open? ? "0.8" : "0.5"
    end
  end
end
