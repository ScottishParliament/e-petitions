require 'rails_helper'

RSpec.describe PetitionCSVPresenter do
  include TimestampsSpecHelper

  describe "#initialize" do
    it "initializes the presenter with a petition" do
      presenter = described_class.new("foo")
      expect(presenter.petition).to eq("foo")
    end
  end

  describe ".fields" do
    it "returns a list of all the fields to serialize" do
      expect(described_class.fields).to be_an Array
    end
  end

  describe "#to_csv" do
    subject { described_class.new(petition).to_csv }

    %w[open closed completed].each do |state_name|
      context "with a #{state_name} petition" do
        let!(:petition) { FactoryBot.create "#{state_name}_petition" }

        specify { is_expected.to eq(csvd_public_petition petition) }
      end
    end

    %w[pending validated sponsored flagged hidden rejected].each do |state_name|
      context "with a #{state_name} petition" do
        let!(:petition) { FactoryBot.create "#{state_name}_petition" }

        specify { is_expected.to eq(csvd_not_public_petition petition) }
      end
    end

    describe "closed_at" do
      let(:petition) { FactoryBot.create(:completed_petition) }
      let(:index) { PetitionCSVPresenter.fields.find_index(:closed_at) }

      it "is present in the CSV headers" do
        expect(index).to_not be_nil
      end

      it "maps to the petition completed_at value" do
        expect(CSV.parse(subject).first.at(index)).to eq timestampify(petition.completed_at)
      end
    end
  end

  def csvd_not_public_petition(petition)
    [
      "https://petitions.parliament.scot/petitions/#{petition.to_param}",
      "https://moderate.petitions.parliament.scot/admin/petitions/#{petition.to_param}",
      ('PP%04d' % petition.id),
      petition.pe_number_id,
      petition.action,
      petition.background,
      petition.previous_action,
      petition.additional_details,
      petition.status,
      petition.creator_name,
      petition.creator_email,
      petition.signature_count,
      petition.rejection_code,
      petition.rejection_details,
      petition.debate_date,
      petition.debate_transcript_url,
      petition.debate_video_url,
      petition.debate_pack_url,
      petition.debate_overview,
      timestampify(petition.created_at),
      timestampify(petition.updated_at),
      timestampify(petition.open_at),
      timestampify(petition.completed_at),
      datestampify(petition.scheduled_debate_date),
      timestampify(petition.referral_threshold_reached_at),
      timestampify(petition.debate_threshold_reached_at),
      timestampify(petition.rejected_at),
      timestampify(petition.debate_outcome_at),
      timestampify(petition.moderation_threshold_reached_at),
      petition.note.try(:details)
    ].join(",") + "\n"
  end

  def csvd_public_petition(petition)
    [
      "https://petitions.parliament.scot/petitions/#{petition.to_param}",
      "https://moderate.petitions.parliament.scot/admin/petitions/#{petition.to_param}",
      ('PP%04d' % petition.id),
      ('PE%04d' % petition.pe_number_id),
      petition.action,
      petition.background,
      petition.previous_action,
      petition.additional_details,
      petition.status,
      petition.creator_name,
      petition.creator_email,
      petition.signature_count,
      petition.rejection_code,
      petition.rejection_details,
      petition.debate_date,
      petition.debate_transcript_url,
      petition.debate_video_url,
      petition.debate_pack_url,
      petition.debate_overview,
      timestampify(petition.created_at),
      timestampify(petition.updated_at),
      timestampify(petition.open_at),
      timestampify(petition.completed_at),
      datestampify(petition.scheduled_debate_date),
      timestampify(petition.referral_threshold_reached_at),
      timestampify(petition.debate_threshold_reached_at),
      timestampify(petition.rejected_at),
      timestampify(petition.debate_outcome_at),
      timestampify(petition.moderation_threshold_reached_at),
      petition.note.try(:details)
    ].join(",") + "\n"
  end
end
