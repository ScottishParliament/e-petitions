require 'rails_helper'

RSpec.describe Admin::ScotParlLinkController, type: :controller, admin: true do

  let!(:petition) { FactoryBot.create(:closed_petition) }

  describe "not logged in" do
    describe "GET /show" do
      it "redirects to the login page" do
        get :show, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petitions.parliament.scot/admin/login")
      end
    end

    describe "PATCH /update" do
      it "redirects to the login page" do
        patch :update, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petitions.parliament.scot/admin/login")
      end
    end
  end

  context "logged in as moderator user but need to reset password" do
    let(:user) { FactoryBot.create(:moderator_user, force_password_reset: true) }
    before { login_as(user) }

    describe "GET /show" do
      it "redirects to edit profile page" do
        get :show, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petitions.parliament.scot/admin/profile/#{user.id}/edit")
      end
    end

    describe "PATCH /update" do
      it "redirects to edit profile page" do
        patch :update, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petitions.parliament.scot/admin/profile/#{user.id}/edit")
      end
    end
  end

  describe "logged in as moderator user" do
    let(:user) { FactoryBot.create(:moderator_user) }
    before { login_as(user) }

    describe "GET /show" do
      it "fetches the requested petition" do
        get :show, params: { petition_id: petition.id }
        expect(assigns(:petition)).to eq petition
      end

      it "responds successfully and renders the petitions/show template" do
        get :show, params: { petition_id: petition.id }
        expect(response).to be_successful
        expect(response).to render_template("petitions/show")
      end
    end

    describe "PATCH /update" do
      let(:attributes) do
        {
          scot_parl_link_en: "https://beta.parliament.scot/getting-involved/petitions/PE01319",
          scot_parl_link_gd: "https://beta.parlamaid-alba.scot/a-dol-an-sas/athchuingean/PE01319"
        }
      end

      before do
        patch :update, params: { petition_id: petition.id, petition: attributes }
      end

      it "fetches the requested petition" do
        expect(assigns(:petition)).to eq petition
      end

      it "redirects to the petition show page" do
        expect(response).to redirect_to "https://moderate.petitions.parliament.scot/admin/petitions/#{petition.to_param}"
      end

      it "sets the flash notice message" do
        expect(flash[:notice]).to eq("Petition has been successfully updated")
      end

      it "stores the English link in the database" do
        expect {
          petition.reload
        }.to change {
          petition.scot_parl_link_en
        }.from(nil).to(a_string_matching("beta.parliament.scot"))
      end

      it "stores the Gaelic link in the database" do
        expect {
          petition.reload
        }.to change {
          petition.scot_parl_link_gd
        }.from(nil).to(a_string_matching("beta.parlamaid-alba.scot"))
      end
    end
  end
end
