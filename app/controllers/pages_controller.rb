class PagesController < LocalizedController
  before_action :raise_routing_error, only: :contact, unless: :feedback_disabled?
  before_action :set_cors_headers, only: :trending, if: :json_request?

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
end
