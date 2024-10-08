class Admin::PetitionDetailsController < Admin::AdminController
  before_action :fetch_petition
  helper_method :petition_locale

  def show
  end

  def update
    if update_petition
      redirect_to [:admin, @petition], notice: :petition_updated
    else
      render :show, alert: :petition_not_saved
    end
  end

  private

  def fetch_petition
    @petition = Petition.find(params[:petition_id])
  end

  def update_petition
    I18n.with_locale(petition_locale) do
      @petition.editing = petition_locale
      @petition.attributes = petition_params
    end

    @petition.save
  end

  def petition_params
    params.require(:petition).permit(
      :action, :background, :previous_action, :additional_details, :use_markdown,
      :special_consideration, creator_attributes: [
        :name, :email, :postcode, contact_attributes: [:address, :phone_number]
      ]
    )
  end

  def petition_locale
    params[:locale] == "gd-GB" ? :"gd-GB" : :"en-GB"
  end
end
