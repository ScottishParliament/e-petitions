require 'rails_helper'

RSpec.describe Admin::PetitionsController, type: :controller, admin: true do
  context "when not logged in" do
    describe "GET /admin/petitions" do
      it "redirects to the login page" do
        get :index
        expect(response).to redirect_to("https://moderate.petitions.parliament.scot/admin/login")
      end
    end

    describe "GET /admin/petitions/:id" do
      it "redirects to the login page" do
        get :show, params: { id: "100000" }
        expect(response).to redirect_to("https://moderate.petitions.parliament.scot/admin/login")
      end
    end
  end

  context "when logged in as a moderator but need to reset password" do
    let(:user) { FactoryBot.create(:moderator_user, force_password_reset: true) }
    before { login_as(user) }

    describe "GET /admin/petitions" do
      it "redirects to the edit profile page" do
        get :index
        expect(response).to redirect_to("https://moderate.petitions.parliament.scot/admin/profile/#{user.id}/edit")
      end
    end

    describe "GET /admin/petitions/:id" do
      it "redirects to the edit profile page" do
        get :show, params: { id: "100000" }
        expect(response).to redirect_to("https://moderate.petitions.parliament.scot/admin/profile/#{user.id}/edit")
      end
    end
  end

  context "when logged in as a moderator" do
    let(:user) { FactoryBot.create(:moderator_user) }
    before { login_as(user) }

    describe "GET /admin/petitions" do
      context "when making a HTML request" do
        before { get :index }

        it "returns 200 OK" do
          expect(response).to have_http_status(:ok)
        end

        it "renders the :index template" do
          expect(response).to render_template("admin/petitions/index")
        end
      end

      context "when making a CSV request" do
        before { get :index, format: :csv }

        it "returns a CSV file" do
          expect(response.content_type).to eq("text/csv")
        end

        it "doesn't set the content length" do
          expect(response.content_length).to be_nil
        end

        it "sets the streaming headers" do
          expect(response["X-Accel-Buffering"]).to eq("no")
          expect(response["Cache-Control"]).to match(/no-cache/).or match(/no-store/)
          expect(response["Last-Modified"]).to match(/\w{3}, \d{2} \w{3} \d{4} \d{2}:\d{2}:\d{2} GMT/)
        end

        it "sets the content disposition" do
          expect(response['Content-Disposition']).to match(/attachment; filename=all-petitions-\d{14}\.csv/)
        end
      end

      context "when searching by id" do
        before { get :index, params: { q: "100000" } }

        it "redirects to the admin petition page" do
          expect(response).to redirect_to("https://moderate.petitions.parliament.scot/admin/petitions/100000")
        end
      end
    end

    describe "GET /admin/petitions/:id" do
      context "when the petition doesn't exist" do
        before { get :show, params: { id: "999999" } }

        it "redirects to the admin dashboard page" do
          expect(response).to redirect_to("https://moderate.petitions.parliament.scot/admin")
        end

        it "sets the flash alert message" do
          expect(flash[:alert]).to eq("Sorry, we couldn't find petition 999999")
        end
      end

      context "when the petition exists" do
        let!(:petition) { FactoryBot.create(:petition) }

        before { get :show, params: { id: petition.to_param } }

        it "returns 200 OK" do
          expect(response).to have_http_status(:ok)
        end

        it "renders the :show template" do
          expect(response).to render_template("admin/petitions/show")
        end
      end
    end

    describe "POST /admin/petitions/:id/resend" do
      context "when the petition doesn't exist" do
        before { post :resend, params: { id: "999999" } }

        it "redirects to the admin dashboard page" do
          expect(response).to redirect_to("https://moderate.petitions.parliament.scot/admin")
        end

        it "sets the flash alert message" do
          expect(flash[:alert]).to eq("Sorry, we couldn't find petition 999999")
        end
      end

      context "when the petition exists" do
        let!(:petition) { FactoryBot.create(:petition, action: "Do Stuff!", creator_attributes: { email: "bob@example.com" }) }
        let(:minimum_number_of_sponsors) { 2 }

        before do
          Site.instance.update!(minimum_number_of_sponsors: minimum_number_of_sponsors)

          perform_enqueued_jobs { post :resend, params: { id: petition.to_param } }
        end

        it "redirects to the admin petition page" do
          expect(response).to redirect_to("https://moderate.petitions.parliament.scot/admin/petitions/#{petition.to_param}")
        end

        it "sets the flash alert message" do
          expect(flash[:notice]).to eq("Resent the email to the petition creator and forwarded a copy to the feedback address")
        end

        context "and the site is collecting sponsors" do
          let(:minimum_number_of_sponsors) { 2 }

          it "resends the gather sponsors email to the petition creator" do
            expect(mailbox_for("bob@example.com").last).to have_subject(/Action required: Petition “Do Stuff!”/)
          end

          it "sends a copy of the email to the feedback address" do
            expect(mailbox_for("petitionscommittee@parliament.scot").last).to have_subject(/Action required: Petition “Do Stuff!”/)
          end
        end

        context "and the site is not collecting sponsors" do
          let(:minimum_number_of_sponsors) { 0 }

          it "resends the email to the petition creator" do
            expect(mailbox_for("bob@example.com").last).to have_subject(/Please confirm your email/)
          end

          it "doesn't send a copy of the email to the feedback address" do
            expect(mailbox_for("petitionscommittee@parliament.scot")).to be_empty
          end
        end
      end
    end
  end
end
