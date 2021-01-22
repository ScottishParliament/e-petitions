require 'rails_helper'

RSpec.describe FeedbackSignature, type: :model do
  let(:petition) { FactoryBot.create(:open_petition) }
  let(:signature) { described_class.new(petition) }

  describe ".find" do
    before do
      allow(Petition).to receive(:find).with(petition.id).and_return(petition)
    end

    it "creates an instance wrapping the petition" do
      expect(described_class.find(petition.id)).to eq(signature)
    end
  end

  describe "#name" do
    it "returns 'Petitions team'" do
      expect(signature.name).to eq("Petitions team")
    end
  end

  describe "#email" do
    it "returns 'petitionscommittee@parliament.scot'" do
      expect(signature.email).to eq("petitionscommittee@parliament.scot")
    end
  end

  describe "#notify_by_email?" do
    it "returns true" do
      expect(signature.notify_by_email?).to eq(true)
    end
  end

  describe "#petition" do
    it "returns the petition passed to new" do
      expect(signature.petition).to eq(petition)
    end
  end

  describe "#unsubscribe_token" do
    it "returns a dummy token" do
      expect(signature.unsubscribe_token).to eq("ThisIsNotAToken")
    end
  end

  describe "#locale" do
    context "when the petition was created in English" do
      let(:petition) { FactoryBot.create(:open_petition, locale: "en-GB") }

      it "returns en-GB" do
        expect(signature.locale).to eq("en-GB")
      end
    end

    context "when the petition was created in Scottish" do
      let(:petition) { FactoryBot.create(:open_petition, locale: "gd-GB") }

      it "returns gd-GB" do
        expect(signature.locale).to eq("gd-GB")
      end
    end
  end

  describe "#id" do
    it "returns the petition id" do
      expect(signature.id).to eq(petition.id)
    end
  end

  describe "#to_param" do
    it "returns a dummy id" do
      expect(signature.to_param).to eq("0")
    end
  end

  describe "#to_gid" do
    it "returns a GlobalID instance" do
      expect(signature.to_gid).to eq(GlobalID.new("gid://scots-pets/FeedbackSignature/#{petition.id}"))
    end
  end
end
