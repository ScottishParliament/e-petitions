require 'rails_helper'

RSpec.describe "API request to list petitions", type: :request, show_exceptions: true do
  let(:access_control_allow_origin) { response.headers['Access-Control-Allow-Origin'] }
  let(:access_control_allow_methods) { response.headers['Access-Control-Allow-Methods'] }
  let(:access_control_allow_headers) { response.headers['Access-Control-Allow-Headers'] }

  describe "format" do
    it "responds to JSON" do
      get "/petitions.json"
      expect(response).to be_successful
    end

    it "sets CORS headers" do
      get "/petitions.json"

      expect(response).to be_successful
      expect(access_control_allow_origin).to eq('*')
      expect(access_control_allow_methods).to eq('GET')
      expect(access_control_allow_headers).to eq('Origin, X-Requested-With, Content-Type, Accept')
    end

    it "does not respond to XML" do
      get "/petitions.xml"
      expect(response.status).to eq(406)
    end
  end

  describe "links" do
    let(:links) { json["links"] }

    before do
      FactoryBot.create_list :open_petition, 3
    end

    it "returns a link to itself" do
      get "/petitions.json"

      expect(response).to be_successful
      expect(links).to include("self" => "https://petitions.parliament.scot/petitions.json")
    end

    it "returns a link to the first page of results" do
      get "/petitions.json?count=2"

      expect(response).to be_successful
      expect(links).to include("first" => "https://petitions.parliament.scot/petitions.json?count=2")
    end

    it "returns a link to the last page of results" do
      get "/petitions.json?count=2"

      expect(response).to be_successful
      expect(links).to include("last" => "https://petitions.parliament.scot/petitions.json?count=2&page=2")
    end

    it "returns a link to the next page of results if there is one" do
      get "/petitions.json?count=2"

      expect(response).to be_successful
      expect(links).to include("next" => "https://petitions.parliament.scot/petitions.json?count=2&page=2")
    end

    it "returns a link to the previous page of results if there is one" do
      get "/petitions.json?count=2&page=2"

      expect(response).to be_successful
      expect(links).to include("prev" => "https://petitions.parliament.scot/petitions.json?count=2")
    end

    it "returns no link to the previous page of results when on the first page of results" do
      get "/petitions.json?count=22"

      expect(response).to be_successful
      expect(links).to include("prev" => nil)
    end

    it "returns no link to the next page of results when on the last page of results" do
      get "/petitions.json?count=2&page=2"

      expect(response).to be_successful
      expect(links).to include("next" => nil)
    end

    it "redirects to under_consideration if the provided state is collecting_signatures" do
      get "/petitions.json?state=collecting_signatures"

      expect(response).to redirect_to('/petitions.json?state=under_consideration')
    end

    it "redirects to all petitions if the provided state isn't valid" do
      get "/petitions.json?count=2&page=2&state=rejected"

      expect(response).to redirect_to('/petitions?count=2&page=2&state=all')
    end
  end

  describe "data" do
    let(:data) { json["data"] }
    let(:attributes) { data.dig(0, "attributes") }

    it "returns an empty response if no petitions are public" do
      get "/petitions.json"

      expect(response).to be_successful
      expect(data).to be_empty
    end

    it "returns a list of serialized petitions in the expected order" do
      petition_1 = FactoryBot.create :open_petition, signature_count: 100
      petition_2 = FactoryBot.create :open_petition, signature_count: 300
      petition_3 = FactoryBot.create :open_petition, signature_count: 200

      get "/petitions.json"
      expect(response).to be_successful

      expect(data).to match(
        a_collection_containing_exactly(
          a_hash_including("attributes" => a_hash_including("title" => petition_2.action)),
          a_hash_including("attributes" => a_hash_including("title" => petition_3.action)),
          a_hash_including("attributes" => a_hash_including("title" => petition_1.action))
        )
      )
    end

    it "includes a link to each petitions details" do
      petition = FactoryBot.create :open_petition

      get "/petitions.json"
      expect(response).to be_successful

      expect(data).to match(
        a_collection_containing_exactly(
          a_hash_including(
            "links" => a_hash_including(
              "self" => "https://petitions.parliament.scot/petitions/#{petition.to_param}.json"
            )
          )
        )
      )
    end

    it "includes the creator_name field for open petitions" do
      petition = FactoryBot.create :open_petition, creator_name: "Bob Jones"

      get "/petitions.json"
      expect(response).to be_successful

      expect(data).to match(
        a_collection_containing_exactly(
          a_hash_including("attributes" => a_hash_including("creator_name" => "Bob Jones"))
        )
      )
    end

    it "includes the creator_name field for closed petitions" do
      petition = FactoryBot.create :closed_petition, creator_name: "Bob Jones"

      get "/petitions.json"
      expect(response).to be_successful

      expect(data).to match(
        a_collection_containing_exactly(
          a_hash_including("attributes" => a_hash_including("creator_name" => "Bob Jones"))
        )
      )
    end

    it "includes the creator_name field for completed petitions" do
      petition = FactoryBot.create :completed_petition, creator_name: "Bob Jones"

      get "/petitions.json"
      expect(response).to be_successful

      expect(data).to match(
        a_collection_containing_exactly(
          a_hash_including("attributes" => a_hash_including("creator_name" => "Bob Jones"))
        )
      )
    end

    it "sets the signature count to zero for petitions that didn't collect signatures" do
      petition = FactoryBot.create :closed_petition, collect_signatures: false, signature_count: 1

      get "/petitions.json"
      expect(response).to be_successful

      expect(data).to match(
        a_collection_containing_exactly(
          a_hash_including("attributes" => a_hash_including("signature_count" => 0))
        )
      )
    end

    (Petition::VISIBLE_STATES - Array(Petition::OPEN_STATE)).each do |state_name|
      it "does not include the creator_name field for #{state_name} petitions" do
        petition = FactoryBot.create "#{state_name}_petition".to_sym

      get "/petitions.json"
      expect(response).to be_successful

        expect(data).not_to match(
          a_collection_containing_exactly(
            a_hash_including("attributes" => a_hash_including("creator_name" => "Bob Jones"))
          )
        )
      end
    end

    it "doesn't include the rejection section for non-rejected petitions" do
      petition = FactoryBot.create :open_petition

      get "/petitions.json"
      expect(response).to be_successful

      expect(data).to match(
        a_collection_containing_exactly(
          a_hash_including(
            "attributes" => a_hash_including(
              "rejected_at" => nil,
              "rejection" => nil
            )
          )
        )
      )
    end

    it "includes the rejection section for rejected petitions" do
      petition = \
        FactoryBot.create :rejected_petition,
          rejection_code: "duplicate",
          rejection_details: "This is a duplication of another petition"

      get "/petitions.json"
      expect(response).to be_successful

      expect(data).to match(
        a_collection_containing_exactly(
          a_hash_including(
            "attributes" => a_hash_including(
              "rejection" => a_hash_including(
                "code" => "duplicate",
                "details" => "This is a duplication of another petition"
              )
            )
          )
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

      get "/petitions.json"
      expect(response).to be_successful

      expect(data).to match(
        a_collection_containing_exactly(
          a_hash_including(
            "attributes" => a_hash_including(
              "debate" => a_hash_including(
                "debated_on" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}\z]),
                "overview" => "What happened in the debate",
                "transcript_url" => "https://www.parliament.scot/S5_BusinessTeam/Chamber_Minutes_20210127.pdf",
                "video_url" => "https://www.scottishparliament.tv/meeting/public-petitions-committee-january-27-2021",
                "debate_pack_url" => "http://www.parliament.scot/S5_PublicPetitionsCommittee/Reports/PPCS052020R2.pdf"
              )
            )
          )
        )
      )
    end

    it "includes the topics data" do
      topic = FactoryBot.create :topic, code: "covid-19", name: "COVID-19"

      petition = \
        FactoryBot.create :open_petition,
          topics: [topic.id]

      get "/petitions.json"
      expect(response).to be_successful

      expect(data).to match(
        a_collection_containing_exactly(
          a_hash_including(
            "attributes" => a_hash_including("topics" => [
              "code" => "covid-19", "name" => "COVID-19"
            ])
          )
        )
      )
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

        get "/petitions.json"
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
