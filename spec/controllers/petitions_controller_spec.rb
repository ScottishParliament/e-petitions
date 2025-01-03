require 'rails_helper'

RSpec.describe PetitionsController, type: :controller do
  describe "GET /petitions/new" do
    it "should assign a petition creator" do
      get :new
      expect(assigns[:new_petition]).not_to be_nil
    end

    it "is on stage 'petition'" do
      get :new
      expect(assigns[:new_petition].stage).to eq "petition";
    end

    it "fills in the action if given as query parameter 'q'" do
      get :new, params: { q: "my fancy new action" }
      expect(assigns[:new_petition].action).to eq("my fancy new action")
    end

    context "when creating petitions has been suspended" do
      before do
        allow(Site).to receive(:disable_petition_creation?).and_return(true)
      end

      it "redirects to the home page" do
        get :new
        expect(response).to redirect_to("https://petitions.parliament.scot/")
      end
    end
  end

  describe "POST /petitions/new" do
    let(:params) do
      {
        action: "Save the planet",
        background: "Limit temperature rise at two degrees",
        previous_action: "I spoke to my local MP",
        additional_details: "Global warming is upon us",
        name: "John Mcenroe", email: "john@example.com",
        phone_number: "0141 496 1234", address: "1 Nowhere Road, Cardiff",
        postcode: "G34 0BX", location_code: "GB-SCT",
        privacy_notice: "1"
      }
    end

    let(:constituency) do
      FactoryBot.create(:constituency, :glasgow_provan)
    end

    before do
      allow(Constituency).to receive(:find_by_postcode).with("G340BX").and_return(constituency)
    end

    context "valid post" do
      let(:petition) { Petition.find_by(action: "Save the planet") }

      it "should successfully create a new petition and a signature" do
        perform_enqueued_jobs do
          post :create, params: { stage: "replay_email", petition_creator: params }
        end

        expect(petition.creator).not_to be_nil
        expect(response).to redirect_to("https://petitions.parliament.scot/petitions/thank-you")
      end

      it "should successfully create a new petition and a signature even when email has white space either end" do
        perform_enqueued_jobs do
          post :create, params: { stage: "replay_email", petition_creator: params.merge(email: " john@example.com ") }
        end

        expect(petition).not_to be_nil
        expect(response).to redirect_to("https://petitions.parliament.scot/petitions/thank-you")
      end

      it "should strip a petition action on petition creation" do
        perform_enqueued_jobs do
          post :create, params: { stage: "replay_email", petition_creator: params.merge(action: " Save the planet") }
        end

        expect(petition).not_to be_nil
        expect(response).to redirect_to("https://petitions.parliament.scot/petitions/thank-you")
      end

      it "should send gather sponsors email to petition's creator" do
        perform_enqueued_jobs do
          post :create, params: { stage: "replay_email", petition_creator: params }
        end

        expect(last_email_sent).to deliver_to("john@example.com")
        expect(last_email_sent).to deliver_from(%{"Petitions: Scottish Parliament" <no-reply@petitions.parliament.scot>})
        expect(last_email_sent).to have_subject(/Action required: Petition “Save the planet”/)
      end

      it "should successfully point the signature at the petition" do
        perform_enqueued_jobs do
          post :create, params: { stage: "replay_email", petition_creator: params }
        end

        expect(petition.creator.petition).to eq(petition)
      end

      it "should set user's ip address on signature" do
        perform_enqueued_jobs do
          post :create, params: { stage: "replay_email", petition_creator: params }
        end

        expect(petition.creator.ip_address).to eq("0.0.0.0")
      end

      it "should not be able to set the state of a new petition" do
        perform_enqueued_jobs do
          post :create, params: { stage: "replay_email", petition_creator: params.merge(state: Petition::VALIDATED_STATE) }
        end

        expect(petition.state).to eq(Petition::PENDING_STATE)
      end

      it "should not be able to set the state of a new signature" do
        perform_enqueued_jobs do
          post :create, params: { stage: "replay_email", petition_creator: params.merge(state: Signature::VALIDATED_STATE) }
        end

        expect(petition.creator.state).to eq(Signature::PENDING_STATE)
      end

      it "should set notify_by_email to true on the creator signature" do
        perform_enqueued_jobs do
          post :create, params: { stage: "replay_email", petition_creator: params.merge(state: Signature::VALIDATED_STATE) }
        end

        expect(petition.creator.notify_by_email).to be_truthy
      end

      it "sets the constituency_id on the creator signature, based on the postcode" do
        perform_enqueued_jobs do
          post :create, params: { stage: "replay_email", petition_creator: params.merge(state: Signature::VALIDATED_STATE) }
        end

        expect(petition.creator.constituency_id).to eq("S16000147")
      end

      context "when creator is on the English domain" do
        it "records the English locale on the creator's signature" do
          perform_enqueued_jobs do
            post :create, params: { stage: "replay_email", locale: "en-GB", petition_creator: params.merge(state: Signature::VALIDATED_STATE) }
          end

          expect(petition.creator.locale).to eq("en-GB")
        end
      end

      context "when creator is on the Gaelic domain" do
        it "records the Gaelic locale on the creator's signature" do
          perform_enqueued_jobs do
            post :create, params: { stage: "replay_email", locale: "gd-GB", petition_creator: params.merge(state: Signature::VALIDATED_STATE) }
          end

          expect(petition.creator.locale).to eq("gd-GB")
        end
      end

      context "invalid post" do
        it "should not create a new petition if no action is given" do
          perform_enqueued_jobs do
            post :create, params: { stage: "replay_email", petition_creator: params.merge(action: "") }
          end

          expect(petition).to be_nil
          expect(assigns[:new_petition].errors[:action]).not_to be_blank
          expect(response).to be_successful
        end

        it "should not create a new petition if email is invalid" do
          perform_enqueued_jobs do
            post :create, params: { stage: "replay_email", petition_creator: params.merge(email: "not much of an email") }
          end

          expect(petition).to be_nil
          expect(response).to be_successful
        end

        it "should not create a new petition if privacy_notice is not confirmed" do
          perform_enqueued_jobs do
            post :create, params: { stage: "replay_email", petition_creator: params.merge(privacy_notice: "0") }
          end

          expect(petition).to be_nil
          expect(response).to be_successful
        end

        it "has stage of 'petition' if there is an error on action" do
          perform_enqueued_jobs do
            post :create, params: { stage: "replay_email", petition_creator: params.merge(action: "") }
          end

          expect(assigns[:new_petition].stage).to eq "petition"
        end

        it "has stage of 'petition' if there is an error on background" do
          perform_enqueued_jobs do
            post :create, params: { stage: "replay_email", petition_creator: params.merge(background: "") }
          end

          expect(assigns[:new_petition].stage).to eq "petition"
        end

        it "has stage of 'petition' if there is an error on additional_details" do
          perform_enqueued_jobs do
            post :create, params: { stage: "replay_email", petition_creator: params.merge(additional_details: "a" * 1101) }
          end

          expect(assigns[:new_petition].stage).to eq "petition"
        end

        it "has stage of 'creator' if there is an error on name" do
          perform_enqueued_jobs do
            post :create, params: { stage: "replay_email", petition_creator: params.merge(name: "") }
          end

          expect(assigns[:new_petition].stage).to eq "creator"
        end

        it "has stage of 'creator' if there is an error on postcode" do
          perform_enqueued_jobs do
            post :create, params: { stage: "replay_email", petition_creator: params.merge(postcode: "") }
          end

          expect(assigns[:new_petition].stage).to eq "creator"
        end

        it "has stage of 'creator' if there is an error on location_code" do
          perform_enqueued_jobs do
            post :create, params: { stage: "replay_email", petition_creator: params.merge(location_code: "") }
          end

          expect(assigns[:new_petition].stage).to eq "creator"
        end

        it "has stage of 'replay_email' if there are errors on email and we came from the 'replay_email' stage" do
          perform_enqueued_jobs do
            post :create, params: { stage: "replay_email", petition_creator: params.merge(email: "") }
          end

          expect(assigns[:new_petition].stage).to eq "replay_email"
        end

        it "has stage of 'creator' if there are errors on email and we came from the 'creator' stage" do
          perform_enqueued_jobs do
            post :create, params: { stage: "creator", petition_creator: params.merge(email: "") }
          end

          expect(assigns[:new_petition].stage).to eq "creator"
        end

        it "has stage of 'creator' if there are errors on privacy_notice and we came from the 'creator' stage" do
          perform_enqueued_jobs do
            post :create, params: { stage: "creator", petition_creator: params.merge(privacy_notice: "0") }
          end

          expect(assigns[:new_petition].stage).to eq "creator"
        end
      end
    end

    context "when the IP address is blocked" do
      let(:petition) { Petition.find_by(action: "Save the planet") }
      let(:rate_limit) { RateLimit.first! }

      before do
        rate_limit.update!(blocked_ips: "0.0.0.0")
      end

      it "should not create a new petition and a signature" do
        perform_enqueued_jobs do
          post :create, params: { stage: "replay_email", petition_creator: params }
        end

        expect(petition).to be_nil
        expect(response).to redirect_to("https://petitions.parliament.scot/petitions/thank-you")
      end
    end

    context "when creating petitions has been suspended" do
      before do
        allow(Site).to receive(:disable_petition_creation?).and_return(true)
      end

      it "redirects to the home page" do
        perform_enqueued_jobs do
          post :create, params: { stage: "replay_email", petition_creator: params }
        end

        expect(response).to redirect_to("https://petitions.parliament.scot/")
      end
    end
  end

  describe "GET /petitions/:id" do
    let(:petition) { double }

    it "assigns the given petition" do
      allow(petition).to receive(:pe_number_id).and_return(petition)
      allow(petition).to receive(:collecting_sponsors?).and_return(false)
      allow(petition).to receive(:in_moderation?).and_return(false)
      allow(petition).to receive(:moderated?).and_return(true)
      allow(Petition).to receive_message_chain(:show, find: petition.pe_number_id)

      get :show, params: { id: "PE0002" }
      expect(assigns(:petition)).to eq(petition)
    end

    it "does not allow hidden petitions to be shown" do
      expect {
        allow(Petition).to receive_message_chain(:visible, :find).and_raise ActiveRecord::RecordNotFound
        get :show, params: { id: "PP0001" }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context "when the petition is hidden after opening" do
      let(:petition) { FactoryBot.create(:hidden_petition, open_at: 1.month.ago) }

      it "raises a Site::PetitionRemoved exception" do
        expect {
          get :show, params: { id: petition.to_param }
        }.to raise_error(Site::PetitionRemoved)
      end
    end
  end

  describe "GET /petitions" do
    context "when no state param is provided" do
      it "is successful" do
        get :index
        expect(response).to be_successful
      end

      it "exposes a search scoped to the all facet" do
        get :index
        expect(assigns(:petitions).scope).to eq :all
      end
    end

    context "when a state param is provided" do
      context "but it is not a public facet from the locale file" do
        it "redirects to itself with state=all" do
          get :index, params: { state: "awaiting_monkey" }
          expect(response).to redirect_to "https://petitions.parliament.scot/petitions?state=all"
        end

        it "preserves other params when it redirects" do
          get :index, params: { q: "what is clocks", state: "awaiting_monkey" }
          expect(response).to redirect_to "https://petitions.parliament.scot/petitions?q=what+is+clocks&state=all"
        end
      end

      context "and it is a public facet from the locale file" do
        it "is successful" do
          get :index, params: { state: "closed" }
          expect(response).to be_successful
        end

        it "exposes a search scoped to the state param" do
          get :index, params: { state: "closed" }
          expect(assigns(:petitions).scope).to eq :closed
        end
      end

      context "and it is an array" do
        it "redirects to itself with state=all" do
          get :index, params: { state: [ "l337haxxor" ] }
          expect(response).to redirect_to "https://petitions.parliament.scot/petitions?state=all"
        end

        it "preserves other params when it redirects" do
          get :index, params: { q: "what is clocks", state: [ "l337haxxor" ] }
          expect(response).to redirect_to "https://petitions.parliament.scot/petitions?q=what+is+clocks&state=all"
        end
      end

      context "and it is a hash" do
        it "redirects to itself with state=all" do
          get :index, params: { state: { l337: "haxxor" } }
          expect(response).to redirect_to "https://petitions.parliament.scot/petitions?state=all"
        end

        it "preserves other params when it redirects" do
          get :index, params: { q: "what is clocks", state: { l337: "haxxor" } }
          expect(response).to redirect_to "https://petitions.parliament.scot/petitions?q=what+is+clocks&state=all"
        end
      end
    end

    context "when a page param is provided" do
      context "and it is an array" do
        it "is treated as being on the first page" do
          get :index, params: { page: [ "l337haxxor" ] }
          expect(assigns(:petitions).current_page).to eq 1
        end
      end

      context "and it is a hash" do
        it "is treated as being on the first page" do
          get :index, params: { page: { l337: "haxxor" } }
          expect(assigns(:petitions).current_page).to eq 1
        end
      end

      context "and it is out of range" do
        it "is treated as being on the first page" do
          get :index, params: { page: "414141414141414141" }
          expect(assigns(:petitions).current_page).to eq 1
        end
      end
    end

    context "when a count param is provided" do
      context "and it is an array" do
        it "uses the default count" do
          get :index, params: { count: [ "l337haxxor" ] }
          expect(assigns(:petitions).page_size).to eq 15
        end
      end

      context "and it is a hash" do
        it "uses the default count" do
          get :index, params: { count: { l337: "haxxor" } }
          expect(assigns(:petitions).page_size).to eq 15
        end
      end

      context "and it is out of range" do
        it "uses the default count" do
          get :index, params: { count: "414141414141414141" }
          expect(assigns(:petitions).page_size).to eq 15
        end
      end
    end
  end

  describe "GET /petitions/check" do
    it "is successful" do
      get :check
      expect(response).to be_successful
    end

    context "when creating petitions has been suspended" do
      before do
        allow(Site).to receive(:disable_petition_creation?).and_return(true)
      end

      it "redirects to the home page" do
        get :check
        expect(response).to redirect_to("https://petitions.parliament.scot/")
      end
    end
  end

  describe "GET /petitions/check-results" do
    it "is successful" do
      get :check_results, params: { q: "action" }
      expect(response).to be_successful
    end

    context "when creating petitions has been suspended" do
      before do
        allow(Site).to receive(:disable_petition_creation?).and_return(true)
      end

      it "redirects to the home page" do
      get :check_results, params: { q: "action" }
        expect(response).to redirect_to("https://petitions.parliament.scot/")
      end
    end
  end

  describe "GET /petitions/:id/moderation-info" do
    let(:petition) { double }

    context "when petitions do not need to collect sponsors to be submitted for moderation" do
      before do
        Site.instance.update!(
          minimum_number_of_sponsors: 0,
          threshold_for_moderation: 0
        )
      end

      it "redirects to not found" do
        allow(petition).to receive(:collecting_sponsors?).and_return(false)
        allow(petition).to receive(:in_moderation?).and_return(false)
        allow(petition).to receive(:moderated?).and_return(true)
        allow(petition).to receive(:pe_number_id).and_return(petition)
        allow(Petition).to receive_message_chain(:show, find: petition.pe_number_id)

        expect {
          get :moderation_info, params: { id: "PP0001" }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "GET /petitions/:id/gathering-support" do
    let(:petition) { double }

    context "when petitions do not need to collect sponsors to be submitted for moderation" do
      before do
        Site.instance.update!(
          minimum_number_of_sponsors: 0,
          threshold_for_moderation: 0
        )
      end

      it "redirects to not found" do
        allow(petition).to receive(:collecting_sponsors?).and_return(false)
        allow(petition).to receive(:in_moderation?).and_return(false)
        allow(petition).to receive(:moderated?).and_return(true)
        allow(petition).to receive(:pe_number_id).and_return(petition)
        allow(Petition).to receive_message_chain(:show, find: petition.pe_number_id)

        expect {
          get :gathering_support, params: { id: "PP0001" }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
