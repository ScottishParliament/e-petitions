require 'rails_helper'

RSpec.describe "API request to show a petition", type: :request, show_exceptions: true do
  let(:petition) { FactoryBot.create :open_petition, committee_note: "This petition action was found to be false" }
  let(:attributes) { json["data"]["attributes"] }

  let(:access_control_allow_origin) { response.headers['Access-Control-Allow-Origin'] }
  let(:access_control_allow_methods) { response.headers['Access-Control-Allow-Methods'] }
  let(:access_control_allow_headers) { response.headers['Access-Control-Allow-Headers'] }

  describe "format" do
    it "responds to JSON" do
      get "/petitions/#{petition.to_param}.json"
      expect(response).to be_successful
    end

    it "sets CORS headers" do
      get "/petitions/#{petition.to_param}.json"

      expect(response).to be_successful
      expect(access_control_allow_origin).to eq('*')
      expect(access_control_allow_methods).to eq('GET')
      expect(access_control_allow_headers).to eq('Origin, X-Requested-With, Content-Type, Accept')
    end

    it "does not respond to XML" do
      get "/petitions/#{petition.to_param}.xml"
      expect(response.status).to eq(406)
    end
  end

  describe "links" do
    let(:links) { json["links"] }

    it "returns a link to itself" do
      get "/petitions/#{petition.to_param}.json"

      expect(response).to be_successful
      expect(links).to include("self" => "https://petitions.parliament.scot/petitions/#{petition.to_param}.json")
    end
  end

  describe "data" do
    it "returns the petition with the expected fields" do
      get "/petitions/#{petition.to_param}.json"
      expect(response).to be_successful

      expect(attributes).to match(
        a_hash_including(
          "title" => a_string_matching(petition.action),
          "summary" => a_string_matching(petition.background),
          "previous_action" => a_string_matching(petition.previous_action),
          "background_information" => a_string_matching(petition.additional_details),
          "petitioner" => a_string_matching(petition.creator.name),
          "committee_note" => a_string_matching(petition.committee_note),
          "status" => a_string_matching(petition.status),
          "signature_count" => eq_to(petition.signature_count),
          "opened_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
          "created_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
          "updated_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z])
        )
      )
    end

    context "when the petition is closed" do
      let(:petition) { FactoryBot.create :closed_petition }

      it "returns the closed_at timestamp as under_consideration_at" do
        get "/petitions/#{petition.to_param}.json"

        expect(response).to be_successful

        expect(attributes)
          .to match(
                a_hash_including(
                  "status" => "under_consideration",
                  "under_consideration_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z])
                )
              )
      end
    end

    context "when the petition is completed" do
      let(:petition) { FactoryBot.create :completed_petition }

      it "returns the completed_at timestamp as closed_at" do
        get "/petitions/#{petition.to_param}.json"

        expect(response).to be_successful

        expect(attributes)
          .to match(
                a_hash_including(
                  "status" => "closed",
                  "closed_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z])
                )
              )
      end
    end

    context "when the petition is archived" do
      let(:petition) { FactoryBot.create :archived_petition }

      it "returns the archived_at timestamp date if the petition is archived" do
        get "/petitions/#{petition.to_param}.json"
        expect(response).to be_successful

        expect(attributes)
          .to match(
                a_hash_including(
                  "status" => "closed",
                  "archived_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z])
                )
              )
      end
    end

    it "returns the submitted_on date if the petition was submitted on paper" do
      petition = FactoryBot.create :paper_petition

      get "/petitions/#{petition.to_param}.json"
      expect(response).to be_successful

      expect(attributes).to match(
        a_hash_including(
          "submitted_on_paper" => true,
          "submitted_on" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}\z])
        )
      )
    end

    it "doesn't include the rejection section for non-rejected petitions" do
      petition = FactoryBot.create :open_petition

      get "/petitions/#{petition.to_param}.json"
      expect(response).to be_successful

      expect(attributes).to match(
        a_hash_including(
          "rejected_at" => nil,
          "rejection" => nil
        )
      )
    end

    it "includes the rejection section for rejected petitions" do
      petition = \
        FactoryBot.create :rejected_petition,
          rejection_code: "duplicate",
          rejection_details: "This is a duplication of another petition"

      get "/petitions/#{petition.to_param}.json"
      expect(response).to be_successful

      expect(attributes).to match(
        a_hash_including(
          "rejected_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
          "rejection" => a_hash_including(
            "code" => "duplicate",
            "details" => "This is a duplication of another petition"
          )
        )
      )
    end

    it "includes the date and time at which the thresholds were reached" do
      petition = \
        FactoryBot.create :open_petition,
          moderation_threshold_reached_at: 1.month.ago,
          referral_threshold_reached_at: 1.weeks.ago,
          debate_threshold_reached_at: 1.day.ago

      get "/petitions/#{petition.to_param}.json"
      expect(response).to be_successful

      expect(attributes).to match(
        a_hash_including(
          "moderation_threshold_reached_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
          "referral_threshold_reached_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
          "debate_threshold_reached_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
        )
      )
    end

    it "includes the date and time at which the petition was referred" do
      petition = FactoryBot.create :referred_petition

      get "/petitions/#{petition.to_param}.json"
      expect(response).to be_successful

      expect(attributes).to match(
        a_hash_including(
          "referred_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z])
        )
      )
    end

    it "includes the date when a petition is scheduled for a debate" do
      petition = FactoryBot.create :scheduled_debate_petition

      get "/petitions/#{petition.to_param}.json"
      expect(response).to be_successful

      expect(attributes).to match(
        a_hash_including(
          "scheduled_debate_date" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}\z])
        )
      )
    end

    it "includes the debate section for petitions that have been debated" do
      petition = \
        FactoryBot.create :debated_petition,
          debated_on: 1.day.ago,
          overview: "What happened in the debate",
          transcript_url: "https://www.parliament.scot/S5_BusinessTeam/Chamber_Minutes_20210127.pdf",
          video_url: "https://www.scottishparliament.tv/meeting/public-petitions-committee-january-27-2021",
          debate_pack_url: "http://www.parliament.scot/S5_PublicPetitionsCommittee/Reports/PPCS052020R2.pdf"

      get "/petitions/#{petition.to_param}.json"
      expect(response).to be_successful

      expect(attributes).to match(
        a_hash_including(
          "debate_outcome_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
          "debate" => a_hash_including(
            "debated_on" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}\z]),
            "overview" => "What happened in the debate",
            "transcript_url" => "https://www.parliament.scot/S5_BusinessTeam/Chamber_Minutes_20210127.pdf",
            "video_url" => "https://www.scottishparliament.tv/meeting/public-petitions-committee-january-27-2021",
            "debate_pack_url" => "http://www.parliament.scot/S5_PublicPetitionsCommittee/Reports/PPCS052020R2.pdf"
          )
        )
      )
    end

    it "includes the topics data" do
      topic = FactoryBot.create :topic, code: "covid-19", name: "COVID-19"

      petition = \
        FactoryBot.create :open_petition,
          topics: [topic.id]

      get "/petitions/#{petition.to_param}.json"
      expect(response).to be_successful

      expect(attributes).to match(
        a_hash_including("topics" => [
          "code" => "covid-19", "name" => "COVID-19"
        ])
      )
    end

    it "includes the signatures by constituency data" do
      petition = FactoryBot.create :open_petition

      FactoryBot.create :constituency, :glasgow_provan
      FactoryBot.create :constituency, :dumbarton

      FactoryBot.create :constituency_petition_journal, constituency_id: "S16000147", signature_count: 123, petition: petition
      FactoryBot.create :constituency_petition_journal, constituency_id: "S16000096", signature_count: 456, petition: petition

      get "/petitions/#{petition.to_param}.json"
      expect(response).to be_successful

      expect(attributes).to match(
        a_hash_including(
          "signatures_by_constituency" => a_collection_containing_exactly(
            {
              "id" => "S16000096",
              "name" => "Dumbarton",
              "signature_count" => 456
            },
            {
              "id" => "S16000147",
              "name" => "Glasgow Provan",
              "signature_count" => 123
            }
          )
        )
      )
    end

    it "doesn't include the signatures by constituency data in rejected petitions" do
      petition = FactoryBot.create :rejected_petition

      FactoryBot.create :constituency, :glasgow_provan
      FactoryBot.create :constituency, :dumbarton

      FactoryBot.create :constituency_petition_journal, constituency_id: "S16000147", signature_count: 123, petition: petition
      FactoryBot.create :constituency_petition_journal, constituency_id: "S16000096", signature_count: 456, petition: petition

      get "/petitions/#{petition.to_param}.json"
      expect(response).to be_successful

      expect(attributes.keys).not_to include("signatures_by_constituency")
    end

    it "includes the signatures by country data" do
      petition = FactoryBot.create :open_petition

      FactoryBot.create :country_petition_journal, location_code: "GB-SCT", signature_count: 123456, petition: petition
      FactoryBot.create :country_petition_journal, location_code: "FR", signature_count: 789, petition: petition

      get "/petitions/#{petition.to_param}.json"
      expect(response).to be_successful

      expect(attributes).to match(
        a_hash_including(
          "signatures_by_country" => a_collection_containing_exactly(
            {
              "name" => "Scotland",
              "code" => "GB-SCT",
              "signature_count" => 123456
            },
            {
              "name" => "France",
              "code" => "FR",
              "signature_count" => 789
            }
          )
        )
      )
    end

    it "doesn't include the signatures by country data in rejected petitions" do
      petition = FactoryBot.create :rejected_petition

      FactoryBot.create :country_petition_journal, location_code: "GB-SCT", signature_count: 123456, petition: petition
      FactoryBot.create :country_petition_journal, location_code: "FR", signature_count: 789, petition: petition

      get "/petitions/#{petition.to_param}.json"
      expect(response).to be_successful

      expect(attributes.keys).not_to include("signatures_by_country")
    end

    it "includes the signatures by region data" do
      petition = FactoryBot.create :open_petition

      FactoryBot.create :constituency, :glasgow_provan
      FactoryBot.create :constituency, :dumbarton

      FactoryBot.create :constituency_petition_journal, constituency_id: "S16000147", signature_count: 123, petition: petition
      FactoryBot.create :constituency_petition_journal, constituency_id: "S16000096", signature_count: 456, petition: petition

      get "/petitions/#{petition.to_param}.json"
      expect(response).to be_successful

      expect(attributes).to match(
        a_hash_including(
          "signatures_by_region" => a_collection_containing_exactly(
            {
              "id" => "S17000017",
              "name" => "Glasgow",
              "signature_count" => 123
            },
            {
              "id" => "S17000018",
              "name" => "West Scotland",
              "signature_count" => 456
            }
          )
        )
      )
    end

    it "doesn't include the signatures by constituency data in rejected petitions" do
      petition = FactoryBot.create :rejected_petition

      FactoryBot.create :constituency, :glasgow_provan
      FactoryBot.create :constituency, :dumbarton

      FactoryBot.create :constituency_petition_journal, constituency_id: "S16000147", signature_count: 123, petition: petition
      FactoryBot.create :constituency_petition_journal, constituency_id: "S16000096", signature_count: 456, petition: petition

      get "/petitions/#{petition.to_param}.json"
      expect(response).to be_successful

      expect(attributes.keys).not_to include("signatures_by_region")
    end

    context "when thresholds are disabled" do
      before do
        Site.instance.update! feature_flags: { disable_thresholds_and_debates: true }
      end

      it "doesn't include any threshold or debate data" do
        petition = \
          FactoryBot.create :debated_petition,
            debated_on: 1.day.ago,
            overview: "What happened in the debate",
            transcript_url: "https://www.parliament.scot/S5_BusinessTeam/Chamber_Minutes_20210127.pdf",
            video_url: "https://www.scottishparliament.tv/meeting/public-petitions-committee-january-27-2021",
            debate_pack_url: "http://www.parliament.scot/S5_PublicPetitionsCommittee/Reports/PPCS052020R2.pdf"

        get "/petitions/#{petition.to_param}.json"
        expect(response).to be_successful

        expect(attributes.keys).not_to include(
          "moderation_threshold_reached_at",
          "referral_threshold_reached_at",
          "referred_at",
          "debate_threshold_reached_at",
          "scheduled_debate_date",
          "debate_outcome_at",
          "moderation_threshold_reached_at",
          "debate"
        )
      end
    end
  end
end
