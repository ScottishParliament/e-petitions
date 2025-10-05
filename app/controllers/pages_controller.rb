class PagesController < LocalizedController
  skip_before_action :redirect_to_holding_page, only: :holding

  before_action :raise_routing_error, only: :contact, unless: :feedback_disabled?
  before_action :set_cors_headers, only: :trending, if: :json_request?
  before_action :redirect_to_home_page, only: :holding

  def index
    respond_to do |format|
      format.html
    end
  end

  def trending
    respond_to do |format|
      format.json
    end
  end

  def accessibility
    respond_to do |format|
      format.html
    end
  end

  def contact
    respond_to do |format|
      format.html
    end
  end

  def help
    respond_to do |format|
      format.html
    end
  end

  def holding
    respond_to do |format|
      format.html
    end
  end

  def privacy
    respond_to do |format|
      format.html
    end
  end

  def rules
    respond_to do |format|
      format.html
    end
  end

  def sitemap
    expires_in 1.hour, public: true

    respond_to do |format|
      format.xml
    end
  end

  def browserconfig
    expires_in 1.hour, public: true

    respond_to do |format|
      format.xml
    end
  end

  def manifest
    expires_in 1.hour, public: true

    respond_to do |format|
      format.json
    end
  end

  private

  def redirect_to_home_page
    unless bypass_authenticated?
      redirect_to home_url unless Site.show_holding_page?
    end
  end
end
