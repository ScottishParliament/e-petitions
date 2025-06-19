require 'rails_helper'
require 'rails/dom/testing/assertions'

RSpec.describe Notifications::Template, type: :model do
  let(:api_url) { %r[\Ahttps://email.eu-west-2.amazonaws.com/v2/email/templates] }

  let(:successful_response) do
    { status: 200, body: "{}", headers: { "Content-Type" => "application/json" } }
  end

  let(:not_found_response) do
    { status: 404, body: '{"code":"NotFoundException"}', headers: { "Content-Type" => "application/json" } }
  end

  let(:template_names) do
    described_class::TEMPLATE_NAMES
  end

  describe "schema" do
    it { is_expected.to have_db_column(:id).of_type(:uuid).with_options(null: false) }
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:subject).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:body).of_type(:text).with_options(null: false) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }
  end

  describe "indexes" do
    it { is_expected.to have_db_index(:name).unique }
  end

  describe "validations" do
    subject { FactoryBot.create(:template) }

    before do
      stub_request(:get, api_url).to_return(successful_response)
      stub_request(:put, api_url).to_return(successful_response)
    end

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:subject) }
    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_length_of(:name).is_at_most(100) }
    it { is_expected.to validate_length_of(:subject).is_at_most(100) }
    it { is_expected.to validate_length_of(:body).is_at_most(10000) }
    it { is_expected.to validate_inclusion_of(:name).in_array(template_names) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end

  describe "callbacks" do
    let(:aws_region) { "https://email.eu-west-2.amazonaws.com" }
    let(:template_api) { "#{aws_region}/v2/email/templates" }
    let(:template_url) { "#{template_api}/test-d1f5e610-5455-41ec-b71d-776c61ad9cac"}

    let(:template) do
      FactoryBot.build(:template,
        id: "d1f5e610-5455-41ec-b71d-776c61ad9cac",
        created_at: 2.days.ago,
        updated_at: 2.days.ago,
        name: "email_confirmation_for_signer_en",
        subject: "‘((action_en))’ - please confirm your signature",
        body: <<~MD
          Click this link to sign the petition:

          # ((action_en))

          ((url_en))

          Thanks,
          The Citizen Participation and Public Petitions team
          The Scottish Parliament
        MD
      )
    end

    let(:create_template) do
      hash_including(
        "TemplateName" => "test-d1f5e610-5455-41ec-b71d-776c61ad9cac",
        "TemplateContent" => hash_including(
          "Subject" => "‘{{action_en}}’ - please confirm your signature",
          "Text" => a_string_matching("Click this link to sign the petition"),
          "Html" => a_string_matching("Click this link to sign the petition")
        )
      )
    end

    let(:update_template) do
      hash_including(
        "TemplateContent" => hash_including(
          "Subject" => "‘{{action_en}}’ - please confirm your signature",
          "Text" => a_string_matching("Click this link to sign the petition"),
          "Html" => a_string_matching("Click this link to sign the petition")
        )
      )
    end

    describe "after_save on create" do
      context "when the template doesn't exist" do
        before do
          stub_request(:get, template_url).to_return(not_found_response)
          stub_request(:post, template_api).with(body: create_template).to_return(successful_response)
        end

        it "creates the template in SES" do
          expect {
            template.save
          }.to change(described_class, :count).from(0).to(1)

          expect(a_request(:post, template_api)).to have_been_made
        end
      end

      context "when the template does exist" do
        before do
          stub_request(:get, template_url).to_return(successful_response)
          stub_request(:put, template_url).with(body: update_template).to_return(successful_response)
        end

        it "updates the template in SES" do
          expect {
            template.save
          }.to change(described_class, :count).from(0).to(1)

          expect(a_request(:put, template_url)).to have_been_made
        end
      end
    end

    describe "after_save on update" do
      before do
        stub_request(:get, template_url).to_return(successful_response)
        stub_request(:put, template_url).with(body: update_template).to_return(successful_response)

        template.save!

        WebMock.reset!
      end

      context "when the template doesn't exist" do
        before do
          stub_request(:get, template_url).to_return(not_found_response)
          stub_request(:post, template_api).with(body: create_template).to_return(successful_response)
        end

        it "creates the template in SES" do
          expect {
            template.update(updated_at: Time.current)
          }.to change {
            template.reload.updated_at
          }.to be_within(1.second).of(Time.current)

          expect(a_request(:post, template_api)).to have_been_made
        end
      end

      context "when the template does exist" do
        before do
          stub_request(:get, template_url).to_return(successful_response)
          stub_request(:put, template_url).with(body: update_template).to_return(successful_response)
        end

        it "updates the template in SES" do
          expect {
            template.update(updated_at: Time.current)
          }.to change {
            template.reload.updated_at
          }.to be_within(1.second).of(Time.current)

          expect(a_request(:put, template_url)).to have_been_made
        end
      end
    end

    describe "after_destroy" do
      before do
        stub_request(:get, template_url).to_return(successful_response)
        stub_request(:put, template_url).with(body: update_template).to_return(successful_response)

        template.save!

        WebMock.reset!
      end

      context "when the template doesn't exist" do
        before do
          stub_request(:delete, template_url).to_return(not_found_response)
        end

        it "it tries to delete the template in SES" do
          expect {
            template.destroy
          }.to change(described_class, :count).from(1).to(0)

          expect(a_request(:delete, template_url)).to have_been_made
        end
      end

      context "when the template does exist" do
        before do
          stub_request(:delete, template_url).to_return(successful_response)
        end

        it "it deletes the template in SES" do
          expect {
            template.destroy
          }.to change(described_class, :count).from(1).to(0)

          expect(a_request(:delete, template_url)).to have_been_made
        end
      end
    end
  end

  describe "rendering" do
    let(:template) { described_class.find("d1f5e610-5455-41ec-b71d-776c61ad9cac") }

    before do
      stub_request(:get, api_url).to_return(successful_response)
      stub_request(:put, api_url).to_return(successful_response)

      FactoryBot.create(:template,
        id: "d1f5e610-5455-41ec-b71d-776c61ad9cac",
        name: "email_confirmation_for_signer_en",
        subject: "Please confirm your signature",
        body: <<~MD
          Click this link to sign the petition:

          # ((action_en))

          ((url_en))

          Thanks,
          The Citizen Participation and Public Petitions team
          The Scottish Parliament
        MD
      )
    end

    describe "#html" do
      include Rails::Dom::Testing::Assertions

      def document_root_element
        subject.root
      end

      subject { Nokogiri::HTML(template.html) }

      it "renders correctly" do
        # subject in <title> tag
        assert "head title", "Please confirm your signature"

        assert_select "body" do
          # preheader
          assert_select "span:first-child", /\AClick this link to sign (.+)…\z/
          assert_select "span:first-child:match('style', ?)", "display: none;"
          assert_select "span:first-child:match('style', ?)", "font-size: 1px;"
          assert_select "span:first-child:match('style', ?)", "color: #fff;"
          assert_select "span:first-child:match('style', ?)", "max-height: 0;"

          # branding
          assert_select "table:nth-child(2)" do
            assert_select "img:match('src', ?)", "https://petitions.parliament.scot/email-header.png"
            assert_select "img:match('alt', ?)", "The Scottish Parliament / Pàrlamaid na h-Alba"
            assert_select "img:match('style', ?)", "display: block; border: 0"
            assert_select "img:match('height', ?)", "54"
          end

          # content
          assert_select "table:nth-child(3)" do
            assert_select "tr:nth-child(2)" do
              assert_select "td:nth-child(2)" do
                assert_select "p:first-child", "Click this link to sign the petition:"
                assert_select "h2", "{{action_en}}"
                assert_select "p > a[href='{{url_en}}']", "{{url_en}}"
                assert_select "p:last-child", "Thanks, The Citizen Participation and Public Petitions team The Scottish Parliament"
                assert_select "p:last-child br", count: 2
              end
            end
          end
        end
      end
    end

    describe "#text" do
      subject { template.text }

      it "renders correctly" do
        expect(subject).to eq <<~TEXT
          Click this link to sign the petition:

          {{action_en}}
          -------------
          {{url_en}}

          Thanks,
          The Citizen Participation and Public Petitions team
          The Scottish Parliament


        TEXT
      end
    end
  end
end
