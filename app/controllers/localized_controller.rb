class LocalizedController < ApplicationController
  include FlashI18n

  if ENV['TRANSLATION_ENABLED'].present?
    before_action do
      Language.reload_translations
    end
  end

  before_action :set_locale
  before_action :set_bypass_cookie, if: :bypass_param?
  before_action :redirect_to_english_page, if: :gaelic_disabled?
  before_action :redirect_to_holding_page

  helper_method :holding_page?

  private

  def set_locale
    I18n.locale = locale
  end

  def locale
    case params[:locale]
    when "gd-GB"
      :"gd-GB"
    else
      :"en-GB"
    end
  end

  def english_url?
    params[:locale] == "en-GB"
  end

  def english_url
    URI.parse(request.original_url).tap do |uri|
      uri.host = Site.host_en
    end.to_s
  rescue URI::InvalidURIError => e
    home_en_url
  end

  def holding_page?
    controller_name == "pages" && action_name == "holding"
  end

  def bypass_param?
    params.key?(:bypass)
  end

  def bypass_param
    params[:bypass]
  end

  def bypass_cookie
    cookies.signed[:_spets_bypass]
  end

  def bypass_authenticated?
    Site.bypass_token? && Site.bypass_token == bypass_cookie
  end

  def set_bypass_cookie
    if bypass_param == Site.bypass_token
      cookies.signed[:_spets_bypass] = Site.bypass_token
      redirect_to home_url
    end
  end

  def gaelic_disabled?
    Site.disable_gaelic_website?
  end

  def redirect_to_english_page
    redirect_to english_url, allow_other_host: true unless english_url?
  end

  def redirect_to_holding_page
    unless bypass_authenticated?
      redirect_to holding_url if Site.show_holding_page?
    end
  end

  def raise_routing_error
    raise ActionController::RoutingError, "No route matches #{request.path}"
  end

  def feedback_disabled?
    Site.disable_feedback_sending?
  end
end
