require 'rails_helper'
require_relative 'taggable_examples'
require_relative 'topic_examples'

RSpec.describe Petition, type: :model do
  context "defaults" do
    it "has pending as default state" do
      p = Petition.new
      expect(p.state).to eq("pending")
    end

    it "generates sponsor token" do
      p = FactoryBot.create(:petition, :sponsor_token => nil)
      expect(p.sponsor_token).not_to be_nil
    end
  end

  describe "associations" do
    it { is_expected.to have_one(:debate_outcome).dependent(:destroy) }

    it { is_expected.to have_many(:emails).dependent(:destroy) }
    it { is_expected.to have_many(:invalidations) }
  end

  describe "callbacks" do
    let(:now) { Time.current }

    context "when creating a petition" do
      before do
        Site.update_all(last_petition_created_at: nil)
      end

      it "updates the site's last_petition_created_at column" do
        expect {
          FactoryBot.create(:petition)
        }.to change {
          Site.last_petition_created_at
        }.from(nil).to(be_within(1.second).of(now))
      end
    end

    context "when the state changes" do
      let(:user) { FactoryBot.create(:moderator_user) }

      before do
        Admin::Current.user = user
      end

      [
        %w[pending validated],
        %w[validated sponsored],
        %w[validated flagged],
        %w[sponsored flagged],
        %w[flagged sponsored],
        %w[open closed],
        %w[rejected flagged],
        %w[rejected sponsored]
      ].each do |initial, desired|
        context "from '#{initial}' to '#{desired}'" do
          let(:petition) { FactoryBot.create(:"#{initial}_petition", state: initial) }

          before do
            expect(Admin::Current).not_to receive(:user)
          end

          it "doesn't update the moderated by user" do
            expect {
              petition.update!(state: desired)
            }.not_to change {
              petition.moderated_by
            }.from(nil)
          end

          it "updates the state" do
            expect {
              petition.update!(state: desired)
            }.to change {
              petition.state
            }.from(initial).to(desired)
          end
        end
      end

      [
        %w[validated open],
        %w[validated rejected],
        %w[validated hidden],
        %w[sponsored open],
        %w[sponsored rejected],
        %w[sponsored hidden],
        %w[flagged open],
        %w[flagged rejected],
        %w[flagged hidden],
        %w[rejected hidden],
        %w[rejected open]
      ].each do |initial, desired|
        context "from '#{initial}' to '#{desired}'" do
          let(:petition) { FactoryBot.create(:"#{initial}_petition", state: initial) }

          before do
            expect(Admin::Current).to receive(:user).and_return(user)
          end

          it "updates the moderated by user" do
            expect {
              petition.update!(state: desired, open_at: Time.current)
            }.to change {
              petition.moderated_by
            }.from(nil).to(user)
          end

          it "updates the state" do
            expect {
              petition.update!(state: desired, open_at: Time.current)
            }.to change {
              petition.state
            }.from(initial).to(desired)
          end
        end
      end
    end

    context "when moderating a petition" do
      let(:petition) { FactoryBot.create(:sponsored_petition, :translated, moderation_threshold_reached_at: 5.days.ago) }
      let(:user) { FactoryBot.create(:moderator_user) }

      before do
        Admin::Current.user = user
      end

      context "and the petition was opened" do
        it "records the moderation lag" do
          expect {
            petition.moderate(moderation: "approve")
          }.to change {
            petition.reload.moderation_lag
          }.from(nil).to(5)
        end
      end

      context "and the petition was rejected" do
        it "records the moderation lag" do
          expect {
            petition.moderate(moderation: "reject", rejection: { code: "duplicate" })
          }.to change {
            petition.reload.moderation_lag
          }.from(nil).to(5)
        end
      end
    end

    context "when rejecting a petition that didn't get enough signatures" do
      let(:petition) { FactoryBot.create(:open_petition) }

      it "doesn't record a moderation lag" do
        expect {
          petition.close!(now)
        }.not_to change {
          petition.reload.moderation_lag
        }
      end
    end
  end

  context "validations" do
    %i[en-GB gd-GB].each do |locale|
      context "when editing #{locale}" do
        subject { Petition.new(editing: locale) }
        around(:example) {|ex| I18n.with_locale(locale) { ex.run }}
        it { is_expected.to validate_presence_of(:action) }
        it { is_expected.to validate_presence_of(:background) }
        it { is_expected.to validate_presence_of(:previous_action) }
        it { is_expected.to validate_length_of(:action).is_at_most(255) }
        it { is_expected.to validate_length_of(:background).is_at_most(3000) }
        it { is_expected.to validate_length_of(:previous_action).is_at_most(4000) }
        it { is_expected.to validate_length_of(:additional_details).is_at_most(20000) }
      end
    end

    context "when not editing" do
      it { is_expected.not_to validate_presence_of(:action) }
      it { is_expected.not_to validate_presence_of(:background) }
      it { is_expected.not_to validate_length_of(:action).is_at_most(255) }
      it { is_expected.not_to validate_length_of(:background).is_at_most(3000) }
      it { is_expected.not_to validate_length_of(:previous_action).is_at_most(4000) }
      it { is_expected.not_to validate_length_of(:additional_details).is_at_most(20000) }
    end

    it { is_expected.to validate_presence_of(:creator).with_message(/must be completed/) }

    it { is_expected.to have_db_column(:locale).of_type(:string).with_options(limit: 7, null: false, default: "en-GB") }
    it { is_expected.to have_db_column(:action_en).of_type(:string).with_options(limit: 255, null: true) }
    it { is_expected.to have_db_column(:action_gd).of_type(:string).with_options(limit: 255, null: true) }
    it { is_expected.to have_db_column(:background_en).of_type(:string).with_options(limit: 3000, null: true) }
    it { is_expected.to have_db_column(:background_gd).of_type(:string).with_options(limit: 3000, null: true) }
    it { is_expected.to have_db_column(:previous_action_en).of_type(:text).with_options(null: true) }
    it { is_expected.to have_db_column(:previous_action_gd).of_type(:text).with_options(null: true) }
    it { is_expected.to have_db_column(:additional_details_en).of_type(:text).with_options(null: true) }
    it { is_expected.to have_db_column(:additional_details_gd).of_type(:text).with_options(null: true) }
    it { is_expected.to have_db_column(:collect_signatures).of_type(:boolean).with_options(default: true, null: false) }

    it { is_expected.to validate_presence_of(:state).with_message("State ‘’ not recognised") }
    it { is_expected.not_to allow_value("unknown").for(:state) }

    it { is_expected.to allow_value("pending").for(:state) }
    it { is_expected.to allow_value("validated").for(:state) }
    it { is_expected.to allow_value("sponsored").for(:state) }
    it { is_expected.to allow_value("flagged").for(:state) }
    it { is_expected.to allow_value("open").for(:state) }
    it { is_expected.to allow_value("rejected").for(:state) }
    it { is_expected.to allow_value("hidden").for(:state) }

    context "when state is open" do
      subject { FactoryBot.build(:open_petition) }

      it { is_expected.not_to allow_value(nil).for(:open_at) }
      it { is_expected.to allow_value(Time.current).for(:open_at) }
    end
  end

  describe "scopes" do
    describe ".trending" do
      let(:now) { 1.minute.from_now }
      let(:interval) { 1.hour.ago(now)..now }

      before(:each) do
        11.times do |count|
          petition = FactoryBot.create(:open_petition, action: "petition ##{count+1}", last_signed_at: Time.current)
          count.times { FactoryBot.create(:validated_signature, petition: petition) }
        end

        @petition_with_old_signatures = FactoryBot.create(:open_petition, action: "petition out of range", last_signed_at: 2.hours.ago)
        @petition_with_old_signatures.signatures.first.update_attribute(:validated_at, 2.hours.ago)
      end

      it "returns petitions trending for the last hour" do
        expect(Petition.trending(interval).map(&:id).include?(@petition_with_old_signatures.id)).to be_falsey
      end

      it "returns the signature count for the last hour as an additional attribute" do
        expect(Petition.trending(interval).first.signature_count_in_period).to eq(11)
        expect(Petition.trending(interval).last.signature_count_in_period).to eq(9)
      end

      it "limits the result to 3 petitions" do
        # 13 petitions signed in the last hour
        2.times do |count|
          petition = FactoryBot.create(:open_petition, action: "petition ##{count+1}", last_signed_at: Time.current)
          count.times { FactoryBot.create(:validated_signature, petition: petition) }
        end

        expect(Petition.trending(interval).to_a.size).to eq(3)
      end

      it "excludes petitions that are not open" do
        petition = FactoryBot.create(:validated_petition)
        20.times{ FactoryBot.create(:validated_signature, petition: petition) }

        expect(Petition.trending(interval)).not_to include(petition)
      end

      it "excludes signatures that have been invalidated" do
        petition = Petition.trending(interval).first
        signature = FactoryBot.create(:validated_signature, petition: petition)

        expect(Petition.trending(interval).first.signature_count_in_period).to eq(12)

        signature.invalidate!
        expect(Petition.trending(interval).first.signature_count_in_period).to eq(11)
      end
    end

    describe ".threshold" do
      before :each do
        @p1 = FactoryBot.create(:open_petition, signature_count: Site.threshold_for_debate)
        @p2 = FactoryBot.create(:open_petition, signature_count: Site.threshold_for_debate + 1)
        @p3 = FactoryBot.create(:open_petition, signature_count: Site.threshold_for_debate - 1)
        @p4 = FactoryBot.create(:open_petition, signature_count: Site.threshold_for_debate * 2)
      end

      it "returns 3 petitions over the threshold" do
        petitions = Petition.threshold
        expect(petitions.size).to eq(3)
        expect(petitions).to include(@p1, @p2, @p4)
      end
    end

    describe ".for_state" do
      before :each do
        @p1 = FactoryBot.create(:petition, :state => Petition::PENDING_STATE)
        @p2 = FactoryBot.create(:petition, :state => Petition::VALIDATED_STATE)
        @p3 = FactoryBot.create(:petition, :state => Petition::PENDING_STATE)
        @p4 = FactoryBot.create(:open_petition, :closed_at => 1.day.from_now)
        @p5 = FactoryBot.create(:petition, :state => Petition::HIDDEN_STATE)
        @p6 = FactoryBot.create(:closed_petition, :closed_at => 1.day.ago)
        @p7 = FactoryBot.create(:petition, :state => Petition::SPONSORED_STATE)
        @p8 = FactoryBot.create(:petition, :state => Petition::FLAGGED_STATE)
      end

      it "returns 2 pending petitions" do
        petitions = Petition.for_state(Petition::PENDING_STATE)
        expect(petitions.size).to eq(2)
        expect(petitions).to include(@p1, @p3)
      end

      it "returns 1 validated, sponsored, flagged, open, closed and hidden petitions" do
        [[Petition::VALIDATED_STATE, @p2], [Petition::OPEN_STATE, @p4],
         [Petition::HIDDEN_STATE, @p5], [Petition::CLOSED_STATE, @p6],
         [Petition::SPONSORED_STATE, @p7], [Petition::FLAGGED_STATE, @p8]].each do |state_and_petition|
          petitions = Petition.for_state(state_and_petition[0])
          expect(petitions.size).to eq(1)
          expect(petitions).to eq([state_and_petition[1]])
        end
      end
    end

    describe ".visible" do
      before :each do
        @hidden_petition_1 = FactoryBot.create(:petition, :state => Petition::PENDING_STATE)
        @hidden_petition_2 = FactoryBot.create(:petition, :state => Petition::VALIDATED_STATE)
        @hidden_petition_3 = FactoryBot.create(:petition, :state => Petition::HIDDEN_STATE)
        @hidden_petition_4 = FactoryBot.create(:petition, :state => Petition::SPONSORED_STATE)
        @hidden_petition_5 = FactoryBot.create(:petition, :state => Petition::FLAGGED_STATE)
        @visible_petition_1 = FactoryBot.create(:open_petition)
        @visible_petition_2 = FactoryBot.create(:rejected_petition)
        @visible_petition_3 = FactoryBot.create(:open_petition, :closed_at => 1.day.ago)
      end

      it "returns only visible petitions" do
        expect(Petition.visible.size).to eq(3)
        expect(Petition.visible).to include(@visible_petition_1, @visible_petition_2, @visible_petition_3)
      end
    end

    describe ".current" do
      let!(:petition) { FactoryBot.create(:open_petition) }
      let!(:other_petition) { FactoryBot.create(:open_petition, created_at: 2.weeks.ago) }
      let!(:closed_petition) { FactoryBot.create(:closed_petition, created_at: 1.week.ago) }
      let!(:rejected_petition) { FactoryBot.create(:rejected_petition) }
      let!(:completed_petition) { FactoryBot.create(:completed_petition) }

      it "doesn't include completed petitions" do
        expect(described_class.current).not_to include(completed_petition)
      end

      it "doesn't include rejected petitions" do
        expect(described_class.current).not_to include(rejected_petition)
      end

      it "returns open and closed petitions, newest first" do
        expect(described_class.current).to match_array([petition, closed_petition, other_petition])
      end
    end

    describe ".not_hidden" do
      let!(:petition) { FactoryBot.create(:hidden_petition) }

      it "returns only petitions that are not hidden" do
        expect(Petition.not_hidden).not_to include(petition)
      end
    end

    describe ".with_debate_outcome" do
      before do
        @p1 = FactoryBot.create(:debated_petition)
        @p2 = FactoryBot.create(:open_petition)
        @p3 = FactoryBot.create(:debated_petition)
        @p4 = FactoryBot.create(:closed_petition)
        @p5 = FactoryBot.create(:rejected_petition)
        @p6 = FactoryBot.create(:sponsored_petition)
        @p7 = FactoryBot.create(:pending_petition)
        @p8 = FactoryBot.create(:validated_petition)
      end

      it "returns only the petitions which have a debate outcome" do
        expect(Petition.with_debate_outcome).to match_array([@p1, @p3])
      end
    end

    describe ".with_debated_outcome" do
      before do
        @p1 = FactoryBot.create(:debated_petition)
        @p2 = FactoryBot.create(:open_petition)
        @p3 = FactoryBot.create(:not_debated_petition)
        @p4 = FactoryBot.create(:closed_petition)
        @p5 = FactoryBot.create(:rejected_petition)
        @p6 = FactoryBot.create(:sponsored_petition)
        @p7 = FactoryBot.create(:pending_petition)
        @p8 = FactoryBot.create(:validated_petition)
        @p9 = FactoryBot.create(:open_petition, scheduled_debate_date: 1.day.ago, debate_state: 'debated')
      end

      it "returns only the petitions which have a positive debate outcome" do
        expect(Petition.with_debated_outcome).to match_array([@p1])
      end
    end

    describe ".awaiting_debate" do
      before do
        @p1 = FactoryBot.create(:open_petition)
        @p2 = FactoryBot.create(:awaiting_debate_petition)
        @p3 = FactoryBot.create(:scheduled_debate_petition, scheduled_debate_date: 2.days.from_now)
        @p4 = FactoryBot.create(:scheduled_debate_petition, scheduled_debate_date: 2.days.ago)
      end

      it "doesn't return petitions that have aren't eligible" do
        expect(Petition.awaiting_debate).not_to include(@p1)
      end

      it "returns petitions that have reached the debate threshold" do
        expect(Petition.awaiting_debate).to include(@p2)
      end

      it "returns petitions that have a scheduled debate date in the future" do
        expect(Petition.awaiting_debate).to include(@p3)
      end

      it "doesn't return petitions that have been debated" do
        expect(Petition.awaiting_debate).not_to include(@p4)
      end
    end

    describe ".by_most_recent_moderation_threshold_reached" do
      let!(:p1) { FactoryBot.create(:sponsored_petition, moderation_threshold_reached_at: 2.days.ago) }
      let!(:p2) { FactoryBot.create(:sponsored_petition, moderation_threshold_reached_at: 1.day.ago) }

      it "returns the petitions in the correct order" do
        expect(Petition.by_most_recent_moderation_threshold_reached.to_a).to eq([p2, p1])
      end
    end

    describe "by_most_relevant_debate_date" do
      before do
        @p1 = FactoryBot.create(:awaiting_debate_petition, debate_threshold_reached_at: 2.weeks.ago)
        @p2 = FactoryBot.create(:awaiting_debate_petition, debate_threshold_reached_at: 4.weeks.ago)
        @p3 = FactoryBot.create(:awaiting_debate_petition, scheduled_debate_date: 4.days.from_now)
        @p4 = FactoryBot.create(:awaiting_debate_petition, scheduled_debate_date: 2.days.from_now)
      end

      it "returns the petitions in the correct order" do
        expect(Petition.by_most_relevant_debate_date.to_a).to eq([@p4, @p3, @p2, @p1])
      end
    end

    describe ".debated" do
      before do
        @p1 = FactoryBot.create(:open_petition)
        @p2 = FactoryBot.create(:open_petition, scheduled_debate_date: 2.days.from_now)
        @p3 = FactoryBot.create(:awaiting_debate_petition)
        @p4 = FactoryBot.create(:not_debated_petition)
        @p5 = FactoryBot.create(:debated_petition)
      end

      it "doesn't return petitions that have aren't eligible" do
        expect(Petition.debated).not_to include(@p1)
      end

      it "doesn't return petitions that have a scheduled debate date" do
        expect(Petition.debated).not_to include(@p2)
      end

      it "doesn't return petitions that have reached the debate threshold" do
        expect(Petition.debated).not_to include(@p3)
      end

      it "doesn't return petitions that have been rejected for a debate" do
        expect(Petition.debated).not_to include(@p4)
      end

      it "returns petitions that have been debated" do
        expect(Petition.debated).to include(@p5)
      end
    end

    describe ".not_debated" do
      before do
        @p1 = FactoryBot.create(:open_petition)
        @p2 = FactoryBot.create(:awaiting_debate_petition)
        @p3 = FactoryBot.create(:awaiting_debate_petition, scheduled_debate_date: 2.days.from_now)
        @p4 = FactoryBot.create(:awaiting_debate_petition, scheduled_debate_date: 2.days.ago)
        @p5 = FactoryBot.create(:not_debated_petition)
      end

      it "doesn't return petitions that have aren't eligible" do
        expect(Petition.not_debated).not_to include(@p1)
      end

      it "doesn't return petitions that have reached the debate threshold" do
        expect(Petition.not_debated).not_to include(@p2)
      end

      it "doesn't return petitions that have a scheduled debate date in the future" do
        expect(Petition.not_debated).not_to include(@p3)
      end

      it "doesn't return petitions that have been debated" do
        expect(Petition.not_debated).not_to include(@p4)
      end

      it "returns petitions that have been rejected for a debate" do
        expect(Petition.not_debated).to include(@p5)
      end
    end

    describe ".awaiting_debate_date" do
      before do
        @p1 = FactoryBot.create(:open_petition)
        @p2 = FactoryBot.create(:awaiting_debate_petition)
        @p3 = FactoryBot.create(:debated_petition)
      end

      it "returns only petitions that reached the debate threshold" do
        expect(Petition.awaiting_debate_date).to include(@p2)
      end

      it "doesn't include petitions that has the debate date" do
        expect(Petition.awaiting_debate_date).not_to include(@p3)
      end
    end

    describe ".referred" do
      let!(:p1) { FactoryBot.create(:open_petition, referral_threshold_reached_at: 1.day.ago) }
      let!(:p2) { FactoryBot.create(:rejected_petition) }
      let!(:p3) { FactoryBot.create(:referred_petition) }
      let!(:p4) { FactoryBot.create(:debated_petition) }

      it "includes petitions that are still open" do
        expect(Petition.referred).to include(p1)
      end

      it "doesn't include petitions that are rejected" do
        expect(Petition.referred).not_to include(p2)
      end

      it "includes petitions that are referred" do
        expect(Petition.referred).to include(p3)
      end

      it "includes petitions that are debated" do
        expect(Petition.referred).to include(p4)
      end
    end

    describe ".by_referred_shortest" do
      let!(:p1) { FactoryBot.create(:referred_petition, referred_at: 1.week.ago) }
      let!(:p2) { FactoryBot.create(:referred_petition, referred_at: 1.month.ago) }
      let!(:p3) { FactoryBot.create(:referred_petition, referred_at: 1.year.ago) }

      it "returns the petitions in the correct order" do
        expect(Petition.by_referred_shortest.to_a).to eq([p1, p2, p3])
      end
    end

    describe ".selectable" do
      before :each do
        @non_selectable_petition_1 = FactoryBot.create(:petition, :state => Petition::PENDING_STATE)
        @non_selectable_petition_2 = FactoryBot.create(:petition, :state => Petition::VALIDATED_STATE)
        @non_selectable_petition_3 = FactoryBot.create(:petition, :state => Petition::SPONSORED_STATE)

        @selectable_petition_1 = FactoryBot.create(:open_petition)
        @selectable_petition_2 = FactoryBot.create(:rejected_petition)
        @selectable_petition_3 = FactoryBot.create(:closed_petition, :closed_at => 1.day.ago)
        @selectable_petition_4 = FactoryBot.create(:petition, :state => Petition::HIDDEN_STATE)
      end

      it "returns only selectable petitions" do
        expect(Petition.selectable.size).to eq(4)
        expect(Petition.selectable).to include(@selectable_petition_1, @selectable_petition_2, @selectable_petition_3, @selectable_petition_4)
      end
    end

    describe '.in_debate_queue' do
      let!(:petition_1) { FactoryBot.create(:open_petition, debate_threshold_reached_at: 1.day.ago) }
      let!(:petition_2) { FactoryBot.create(:open_petition, debate_threshold_reached_at: nil) }
      let!(:petition_3) { FactoryBot.create(:open_petition, debate_threshold_reached_at: nil, scheduled_debate_date: 3.days.from_now) }
      let!(:petition_4) { FactoryBot.create(:open_petition, debate_threshold_reached_at: nil, scheduled_debate_date: nil) }

      subject { described_class.in_debate_queue }

      it 'includes petitions that have reached the debate threshold' do
        expect(subject).to include(petition_1)
        expect(subject).not_to include(petition_2)
      end

      it 'includes petitions that have not reached the debate threshold if they have been scheduled for debate' do
        expect(subject).to include(petition_3)
        expect(subject).not_to include(petition_4)
      end
    end

    describe '.popular_in_constituency' do
      let!(:petition_1) { FactoryBot.create(:open_petition, signature_count: 10) }
      let!(:petition_2) { FactoryBot.create(:open_petition, signature_count: 20) }
      let!(:petition_3) { FactoryBot.create(:open_petition, signature_count: 30) }
      let!(:petition_4) { FactoryBot.create(:open_petition, signature_count: 40) }

      let!(:constituency_1) { FactoryBot.generate(:constituency_id) }
      let!(:constituency_2) { FactoryBot.generate(:constituency_id) }

      let!(:petition_1_journal_1) { FactoryBot.create(:constituency_petition_journal, petition: petition_1, constituency_id: constituency_1, signature_count: 6) }
      let!(:petition_1_journal_2) { FactoryBot.create(:constituency_petition_journal, petition: petition_1, constituency_id: constituency_2, signature_count: 4) }
      let!(:petition_2_journal_2) { FactoryBot.create(:constituency_petition_journal, petition: petition_2, constituency_id: constituency_2, signature_count: 20) }
      let!(:petition_3_journal_1) { FactoryBot.create(:constituency_petition_journal, petition: petition_3, constituency_id: constituency_1, signature_count: 30) }
      let!(:petition_4_journal_1) { FactoryBot.create(:constituency_petition_journal, petition: petition_4, constituency_id: constituency_1, signature_count: 0) }
      let!(:petition_4_journal_2) { FactoryBot.create(:constituency_petition_journal, petition: petition_4, constituency_id: constituency_2, signature_count: 40) }

      it 'excludes petitions that have no journal for the supplied constituency_id' do
        popular = Petition.popular_in_constituency(constituency_1, 4)
        expect(popular).not_to include(petition_2)
      end

      it 'excludes petitions that have a journal with 0 votes for the supplied constituency_id' do
        popular = Petition.popular_in_constituency(constituency_1, 4)
        expect(popular).not_to include(petition_4)
      end

      it 'excludes closed petitions with signatures from the supplied constituency_id' do
        petition_1.update_columns(state: 'closed', closed_at: 3.days.ago)
        popular = Petition.popular_in_constituency(constituency_1, 4)
        expect(popular).not_to include(petition_1)
      end

      it 'excludes rejected petitions with signatures from the supplied constituency_id' do
        petition_1.update_column(:state, Petition::REJECTED_STATE)
        popular = Petition.popular_in_constituency(constituency_1, 4)
        expect(popular).not_to include(petition_1)
      end

      it 'excludes hidden petitions with signatures from the supplied constituency_id' do
        petition_1.update_column(:state, Petition::HIDDEN_STATE)
        popular = Petition.popular_in_constituency(constituency_1, 4)
        expect(popular).not_to include(petition_1)
      end

      it 'includes open petitions with signatures from the supplied constituency_id ordered by the count of signatures' do
        popular = Petition.popular_in_constituency(constituency_1, 2)
        expect(popular).to eq [petition_3, petition_1]
      end

      it 'adds the constituency_signature_count attribute to the retrieved petitions' do
        most_popular = Petition.popular_in_constituency(constituency_1, 1).first
        expect(most_popular).to respond_to :constituency_signature_count
        expect(most_popular.constituency_signature_count).to eq 30
      end

      it 'returns a scope' do
        expect(Petition.popular_in_constituency(constituency_1, 1)).to be_an ActiveRecord::Relation
      end
    end

    describe '.all_popular_in_constituency' do
      let!(:petition_1) { FactoryBot.create(:open_petition, signature_count: 10) }
      let!(:petition_2) { FactoryBot.create(:open_petition, signature_count: 20) }
      let!(:petition_3) { FactoryBot.create(:open_petition, signature_count: 30) }
      let!(:petition_4) { FactoryBot.create(:open_petition, signature_count: 40) }

      let!(:constituency_1) { FactoryBot.generate(:constituency_id) }
      let!(:constituency_2) { FactoryBot.generate(:constituency_id) }

      let!(:petition_1_journal_1) { FactoryBot.create(:constituency_petition_journal, petition: petition_1, constituency_id: constituency_1, signature_count: 6) }
      let!(:petition_1_journal_2) { FactoryBot.create(:constituency_petition_journal, petition: petition_1, constituency_id: constituency_2, signature_count: 4) }
      let!(:petition_2_journal_2) { FactoryBot.create(:constituency_petition_journal, petition: petition_2, constituency_id: constituency_2, signature_count: 20) }
      let!(:petition_3_journal_1) { FactoryBot.create(:constituency_petition_journal, petition: petition_3, constituency_id: constituency_1, signature_count: 30) }
      let!(:petition_4_journal_1) { FactoryBot.create(:constituency_petition_journal, petition: petition_4, constituency_id: constituency_1, signature_count: 0) }
      let!(:petition_4_journal_2) { FactoryBot.create(:constituency_petition_journal, petition: petition_4, constituency_id: constituency_2, signature_count: 40) }

      it 'excludes petitions that have no journal for the supplied constituency_id' do
        popular = Petition.all_popular_in_constituency(constituency_1, 4)
        expect(popular).not_to include(petition_2)
      end

      it 'excludes petitions that have a journal with 0 votes for the supplied constituency_id' do
        popular = Petition.all_popular_in_constituency(constituency_1, 4)
        expect(popular).not_to include(petition_4)
      end

      it 'includes closed petitions with signatures from the supplied constituency_id' do
        petition_1.update_columns(state: 'closed', closed_at: 3.days.ago)
        popular = Petition.all_popular_in_constituency(constituency_1, 4)
        expect(popular).to include(petition_1)
      end

      it 'excludes rejected petitions with signatures from the supplied constituency_id' do
        petition_1.update_column(:state, Petition::REJECTED_STATE)
        popular = Petition.all_popular_in_constituency(constituency_1, 4)
        expect(popular).not_to include(petition_1)
      end

      it 'excludes hidden petitions with signatures from the supplied constituency_id' do
        petition_1.update_column(:state, Petition::HIDDEN_STATE)
        popular = Petition.all_popular_in_constituency(constituency_1, 4)
        expect(popular).not_to include(petition_1)
      end

      it 'includes open petitions with signatures from the supplied constituency_id ordered by the count of signatures' do
        popular = Petition.all_popular_in_constituency(constituency_1, 2)
        expect(popular).to eq [petition_3, petition_1]
      end

      it 'adds the constituency_signature_count attribute to the retrieved petitions' do
        most_popular = Petition.all_popular_in_constituency(constituency_1, 1).first
        expect(most_popular).to respond_to :constituency_signature_count
        expect(most_popular.constituency_signature_count).to eq 30
      end

      it 'returns a scope' do
        expect(Petition.all_popular_in_constituency(constituency_1, 1)).to be_an ActiveRecord::Relation
      end
    end

    describe ".in_moderation" do
      let!(:open_petition) { FactoryBot.create(:open_petition) }
      let!(:recent_petition) { FactoryBot.create(:sponsored_petition, :recent) }
      let!(:overdue_petition) { FactoryBot.create(:sponsored_petition, :overdue) }
      let!(:nearly_overdue_petition) { FactoryBot.create(:sponsored_petition, :nearly_overdue) }

      context "with no arguments" do
        it "returns all petitions awaiting moderation" do
          expect(Petition.in_moderation).to include(recent_petition, overdue_petition, nearly_overdue_petition)
        end

        it "doesn't return petitions in other states" do
          expect(Petition.in_moderation).not_to include(open_petition)
        end
      end

      context "with a :from argument" do
        it "returns all petitions awaiting moderation after the timestamp" do
          expect(Petition.in_moderation(from: 5.days.ago)).to include(recent_petition)
        end

        it "doesn't return petitions awaiting moderation before the timestamp" do
          expect(Petition.in_moderation(from: 5.days.ago)).not_to include(overdue_petition, nearly_overdue_petition)
        end

        it "doesn't return petitions in other states" do
          expect(Petition.in_moderation(from: 5.days.ago)).not_to include(open_petition)
        end
      end

      context "with a :to argument" do
        it "returns all petitions awaiting moderation before the timestamp" do
          expect(Petition.in_moderation(to: 7.days.ago)).to include(overdue_petition)
        end

        it "doesn't return petitions awaiting moderation after the timestamp" do
          expect(Petition.in_moderation(to: 7.days.ago)).not_to include(recent_petition, nearly_overdue_petition)
        end

        it "doesn't return petitions in other states" do
          expect(Petition.in_moderation(to: 7.days.ago)).not_to include(open_petition)
        end
      end

      context "with both a :from and :to argument" do
        it "returns all petitions awaiting moderation between the timestamps" do
          expect(Petition.in_moderation(from: 7.days.ago, to: 5.days.ago)).to include(nearly_overdue_petition)
        end

        it "doesn't return petitions awaiting moderation before the timestamp" do
          expect(Petition.in_moderation(from: 7.days.ago, to: 5.days.ago)).not_to include(overdue_petition)
        end

        it "doesn't return petitions awaiting moderation after the timestamp" do
          expect(Petition.in_moderation(from: 7.days.ago, to: 5.days.ago)).not_to include(recent_petition)
        end

        it "doesn't return petitions in other states" do
          expect(Petition.in_moderation(from: 7.days.ago, to: 5.days.ago)).not_to include(open_petition)
        end
      end
    end

    describe ".recently_in_moderation" do
      let!(:recent_petition) { FactoryBot.create(:sponsored_petition, :recent) }
      let!(:overdue_petition) { FactoryBot.create(:sponsored_petition, :overdue) }
      let!(:nearly_overdue_petition) { FactoryBot.create(:sponsored_petition, :nearly_overdue) }

      it "returns petitions that have recently joined the moderation queue" do
        expect(Petition.recently_in_moderation).to include(recent_petition)
      end

      it "doesn't return petitions that are overdue or nearly overdue" do
        expect(Petition.recently_in_moderation).not_to include(overdue_petition, nearly_overdue_petition)
      end
    end

    describe ".nearly_overdue_in_moderation" do
      let!(:recent_petition) { FactoryBot.create(:sponsored_petition, :recent) }
      let!(:overdue_petition) { FactoryBot.create(:sponsored_petition, :overdue) }
      let!(:nearly_overdue_petition) { FactoryBot.create(:sponsored_petition, :nearly_overdue) }

      it "returns petitions that are nearly overdue for moderation" do
        expect(Petition.nearly_overdue_in_moderation).to include(nearly_overdue_petition)
      end

      it "doesn't return petitions that are overdue or have recently joined the moderation queue" do
        expect(Petition.nearly_overdue_in_moderation).not_to include(recent_petition, overdue_petition)
      end
    end

    describe ".overdue_in_moderation" do
      let!(:recent_petition) { FactoryBot.create(:sponsored_petition, :recent) }
      let!(:overdue_petition) { FactoryBot.create(:sponsored_petition, :overdue) }
      let!(:nearly_overdue_petition) { FactoryBot.create(:sponsored_petition, :nearly_overdue) }

      it "returns petitions that are overdue for moderation" do
        expect(Petition.overdue_in_moderation).to include(overdue_petition)
      end

      it "doesn't return petitions that are nearly overdue or have recently joined the moderation queue" do
        expect(Petition.overdue_in_moderation).not_to include(recent_petition, nearly_overdue_petition)
      end
    end

    describe ".tagged_in_moderation" do
      let!(:recent_petition) { FactoryBot.create(:sponsored_petition, :recent) }
      let!(:overdue_petition) { FactoryBot.create(:sponsored_petition, :overdue) }
      let!(:nearly_overdue_petition) { FactoryBot.create(:sponsored_petition, :nearly_overdue) }
      let!(:tagged_recent_petition) { FactoryBot.create(:sponsored_petition, :recent, :tagged) }
      let!(:tagged_overdue_petition) { FactoryBot.create(:sponsored_petition, :overdue, :tagged) }
      let!(:tagged_nearly_overdue_petition) { FactoryBot.create(:sponsored_petition, :nearly_overdue, :tagged) }

      it "returns petitions that are in the moderation queue and are tagged" do
        expect(Petition.tagged_in_moderation).to include(tagged_recent_petition, tagged_overdue_petition, tagged_nearly_overdue_petition)
      end

      it "doesn't return petitions that are in the moderation queue but are not tagged" do
        expect(Petition.tagged_in_moderation).not_to include(recent_petition, overdue_petition, nearly_overdue_petition)
      end
    end

    describe ".untagged_in_moderation" do
      let!(:recent_petition) { FactoryBot.create(:sponsored_petition, :recent) }
      let!(:overdue_petition) { FactoryBot.create(:sponsored_petition, :overdue) }
      let!(:nearly_overdue_petition) { FactoryBot.create(:sponsored_petition, :nearly_overdue) }
      let!(:tagged_recent_petition) { FactoryBot.create(:sponsored_petition, :recent, :tagged) }
      let!(:tagged_overdue_petition) { FactoryBot.create(:sponsored_petition, :overdue, :tagged) }
      let!(:tagged_nearly_overdue_petition) { FactoryBot.create(:sponsored_petition, :nearly_overdue, :tagged) }

      it "returns petitions that are in the moderation queue and are untagged" do
        expect(Petition.untagged_in_moderation).to include(recent_petition, overdue_petition, nearly_overdue_petition)
      end

      it "doesn't return petitions that are in the moderation queue and are tagged" do
        expect(Petition.untagged_in_moderation).not_to include(tagged_recent_petition, tagged_overdue_petition, tagged_nearly_overdue_petition)
      end
    end

    describe ".signed_since" do
      let!(:petition_1) { FactoryBot.create(:open_petition, last_signed_at: 2.hours.ago) }
      let!(:petition_2) { FactoryBot.create(:open_petition, last_signed_at: 30.minutes.ago) }
      let!(:petition_3) { FactoryBot.create(:open_petition, last_signed_at: 15.minutes.ago) }

      it "returns petitions that have been signed since the timestamp" do
        expect(Petition.signed_since(1.hour.ago)).to include(petition_2, petition_3)
      end

      it "doesn't return petitions that haven't been signed since the timestamp" do
        expect(Petition.signed_since(1.hour.ago)).not_to include(petition_1)
      end
    end

    describe ".paper" do
      let!(:paper_petition) { FactoryBot.create(:paper_petition) }
      let!(:closed_petition) { FactoryBot.create(:closed_petition) }

      it "returns petitions that have been submitted on paper" do
        expect(Petition.paper).to include(paper_petition)
      end

      it "doesn't returns petitions that have been submitted on paper" do
        expect(Petition.paper).not_to include(closed_petition)
      end
    end

    describe ".find" do
      let!(:validated_petition) { FactoryBot.create(:validated_petition) }
      let!(:sponsored_petition) { FactoryBot.create(:sponsored_petition) }
      let!(:rejected_petition) { FactoryBot.create(:rejected_petition) }
      let!(:closed_petition) { FactoryBot.create(:closed_petition) }
      let!(:open_petition) { FactoryBot.create(:open_petition) }
      let!(:hidden_petition) { FactoryBot.create(:hidden_petition) }

      it "returns the correct petition" do
        expect(Petition.find(validated_petition.id)).to eq(validated_petition)
        expect(Petition.find(sponsored_petition.id)).to eq(sponsored_petition)
        expect(Petition.find(rejected_petition.id)).to eq(rejected_petition)
        expect(Petition.find(closed_petition.id)).to eq(closed_petition)
        expect(Petition.find(open_petition.id)).to eq(open_petition)
        expect(Petition.find(hidden_petition.id)).to eq(hidden_petition)
      end
    end
  end

  it_behaves_like "a taggable model"
  it_behaves_like "a model with topics"

  describe "signature count" do
    let(:petition) { FactoryBot.create(:pending_petition) }
    let(:signature) { FactoryBot.create(:pending_signature, petition: petition) }

    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    before do
      petition.validate_creator!
    end

    it "returns 1 (the creator) for a new petition" do
      expect(petition.signature_count).to eq(1)
    end

    it "still returns 1 with a new signature" do
      expect {
        signature
      }.not_to change {
        petition.reload.signature_count
      }.from(1)
    end

    it "returns 2 when signature is validated" do
      expect {
        signature.validate!
      }.to change {
        petition.reload.signature_count
      }.from(1).to(2)
    end
  end

  describe "#can_have_debate_added?" do
    context "with an open petition" do
      let(:petition) { FactoryBot.create(:open_petition) }

      it "returns false" do
        expect(petition.can_have_debate_added?).to eq(false)
      end
    end

    context "with a closed petition" do
      let(:petition) { FactoryBot.create(:closed_petition) }

      it "returns true" do
        expect(petition.can_have_debate_added?).to eq(true)
      end
    end

    context "with a completed petition" do
      let(:petition) { FactoryBot.create(:completed_petition) }

      it "returns true" do
        expect(petition.can_have_debate_added?).to eq(true)
      end
    end

    context "with an archived petition" do
      let(:petition) { FactoryBot.create(:archived_petition) }

      it "returns true" do
        expect(petition.can_have_debate_added?).to eq(true)
      end
    end
  end

  describe "updating the scheduled debate date" do
    context "when the petition is open" do
      context "and the debate date is changed to nil" do
        subject(:petition) {
          FactoryBot.create(:open_petition,
            debate_threshold_reached_at: 1.week.ago,
            scheduled_debate_date: 2.days.from_now,
            debate_state: "scheduled"
          )
        }

        it "sets the debate state to 'awaiting'" do
          expect {
            petition.update(scheduled_debate_date: nil)
          }.to change {
            petition.debate_state
          }.from("scheduled").to("awaiting")
        end
      end

      context "and the debate date is in the future" do
        subject(:petition) {
          FactoryBot.create(:open_petition,
            debate_threshold_reached_at: 1.week.ago,
            scheduled_debate_date: nil,
            debate_state: "awaiting"
          )
        }

        it "sets the debate state to 'scheduled'" do
          expect {
            petition.update(scheduled_debate_date: 2.days.from_now)
          }.to change {
            petition.debate_state
          }.from("awaiting").to("scheduled")
        end
      end

      context "and the debate date is in the past" do
        subject(:petition) {
          FactoryBot.create(:open_petition,
            debate_threshold_reached_at: 1.week.ago,
            scheduled_debate_date: nil,
            debate_state: "awaiting"
          )
        }

        it "sets the debate state to 'debated'" do
          expect {
            petition.update(scheduled_debate_date: 2.days.ago)
          }.to change {
            petition.debate_state
          }.from("awaiting").to("debated")
        end
      end

      context "and the debate date is not changed" do
        subject(:petition) {
          FactoryBot.create(:open_petition,
            debate_threshold_reached_at: 1.week.ago,
            scheduled_debate_date: Date.yesterday,
            debate_state: "scheduled"
          )
        }

        it "does not change the debate state" do
          expect {
            petition.update(open_at: 5.days.ago)
          }.not_to change {
            petition.debate_state
          }
        end
      end

      context "and has not reached the debate threshold" do
        context "and the debate date is changed to nil" do
          subject(:petition) {
            FactoryBot.create(:open_petition,
              debate_threshold_reached_at: nil,
              scheduled_debate_date: 2.days.from_now,
              debate_state: "scheduled"
            )
          }

          it "sets the debate state to 'pending'" do
            expect {
              petition.update(scheduled_debate_date: nil)
            }.to change {
              petition.debate_state
            }.from("scheduled").to("pending")
          end
        end

        context "and the debate date is in the future" do
          subject(:petition) {
            FactoryBot.create(:open_petition,
              debate_threshold_reached_at: nil,
              scheduled_debate_date: nil,
              debate_state: "pending"
            )
          }

          it "sets the debate state to 'scheduled'" do
            expect {
              petition.update(scheduled_debate_date: 2.days.from_now)
            }.to change {
              petition.debate_state
            }.from("pending").to("scheduled")
          end
        end

        context "and the debate date is in the past" do
          subject(:petition) {
            FactoryBot.create(:open_petition,
              debate_threshold_reached_at: nil,
              scheduled_debate_date: nil,
              debate_state: "pending"
            )
          }

          it "sets the debate state to 'debated'" do
            expect {
              petition.update(scheduled_debate_date: 2.days.ago)
            }.to change {
              petition.debate_state
            }.from("pending").to("debated")
          end
        end

        context "and the debate date is not changed" do
          subject(:petition) {
            FactoryBot.create(:open_petition,
              debate_threshold_reached_at: nil,
              scheduled_debate_date: Date.yesterday,
              debate_state: "debated"
            )
          }

          it "does not change the debate state" do
            expect {
              petition.update(open_at: 5.days.ago)
            }.not_to change {
              petition.debate_state
            }
          end
        end
      end
    end

    context "when the petition is closed" do
      context "and the debate date is changed to nil" do
        subject(:petition) {
          FactoryBot.create(:closed_petition,
            debate_threshold_reached_at: 1.week.ago,
            scheduled_debate_date: 2.days.from_now,
            debate_state: "scheduled"
          )
        }

        it "sets the debate state to 'awaiting'" do
          expect {
            petition.update(scheduled_debate_date: nil)
          }.to change {
            petition.debate_state
          }.from("scheduled").to("awaiting")
        end
      end

      context "and the debate date is in the future" do
        subject(:petition) {
          FactoryBot.create(:closed_petition,
            debate_threshold_reached_at: 1.week.ago,
            scheduled_debate_date: nil,
            debate_state: "awaiting"
          )
        }

        it "sets the debate state to 'awaiting'" do
          expect {
            petition.update(scheduled_debate_date: 2.days.from_now)
          }.to change {
            petition.debate_state
          }.from("awaiting").to("scheduled")
        end
      end

      context "and the debate date is in the past" do
        subject(:petition) {
          FactoryBot.create(:closed_petition,
            debate_threshold_reached_at: 1.week.ago,
            scheduled_debate_date: nil,
            debate_state: "awaiting"
          )
        }

        it "sets the debate state to 'debated'" do
          expect {
            petition.update(scheduled_debate_date: 2.days.ago)
          }.to change {
            petition.debate_state
          }.from("awaiting").to("debated")
        end
      end

      context "and the debate date is not changed" do
        subject(:petition) {
          FactoryBot.create(:closed_petition,
            debate_threshold_reached_at: 1.week.ago,
            scheduled_debate_date: Date.yesterday,
            debate_state: "debated"
          )
        }

        it "does not change the debate state" do
          expect {
            petition.update(open_at: 5.days.ago)
          }.not_to change {
            petition.debate_state
          }
        end
      end

      context "and has not reached the debate threshold" do
        context "and the debate date is changed to nil" do
          subject(:petition) {
            FactoryBot.create(:closed_petition,
              debate_threshold_reached_at: nil,
              scheduled_debate_date: 2.days.from_now,
              debate_state: "scheduled"
            )
          }

          it "sets the debate state to 'pending'" do
            expect {
              petition.update(scheduled_debate_date: nil)
            }.to change {
              petition.debate_state
            }.from("scheduled").to("pending")
          end
        end

        context "and the debate date is in the future" do
          subject(:petition) {
            FactoryBot.create(:closed_petition,
              debate_threshold_reached_at: nil,
              scheduled_debate_date: nil,
              debate_state: "pending"
            )
          }

          it "sets the debate state to 'scheduled'" do
            expect {
              petition.update(scheduled_debate_date: 2.days.from_now)
            }.to change {
              petition.debate_state
            }.from("pending").to("scheduled")
          end
        end

        context "and the debate date is in the past" do
          subject(:petition) {
            FactoryBot.create(:closed_petition,
              debate_threshold_reached_at: nil,
              scheduled_debate_date: nil,
              debate_state: "pending"
            )
          }

          it "sets the debate state to 'debated'" do
            expect {
              petition.update(scheduled_debate_date: 2.days.ago)
            }.to change {
              petition.debate_state
            }.from("pending").to("debated")
          end
        end

        context "and the debate date is not changed" do
          subject(:petition) {
            FactoryBot.create(:closed_petition,
              debate_threshold_reached_at: nil,
              scheduled_debate_date: Date.yesterday,
              debate_state: "debated"
            )
          }

          it "does not change the debate state" do
            expect {
              petition.update(open_at: 5.days.ago)
            }.not_to change {
              petition.debate_state
            }
          end
        end
      end
    end
  end

  describe "#can_be_signed?" do
    context "when the petition is in the open state" do
      let(:petition) { FactoryBot.build(:petition, state: Petition::OPEN_STATE) }

      it "is true" do
        expect(petition.can_be_signed?).to be_truthy
      end
    end

    (Petition::STATES - [Petition::OPEN_STATE]).each do |state|
      context "when the petition is in the #{state} state" do
        let(:petition) { FactoryBot.build(:petition, state: state) }

        it "is false" do
          expect(petition.can_be_signed?).to be_falsey
        end
      end
    end
  end

  describe "#open?" do
    context "when the state is open" do
      let(:petition) { FactoryBot.build(:petition, state: Petition::OPEN_STATE) }

      it "returns true" do
        expect(petition.open?).to be_truthy
      end
    end

    context "for other states" do
      (Petition::STATES - [Petition::OPEN_STATE]).each do |state|
        let(:petition) { FactoryBot.build(:petition, state: state) }

        it "is not open when state is #{state}" do
          expect(petition.open?).to be_falsey
        end
      end
    end
  end

  describe "#closed?" do
    context "when the state is closed" do
      let(:petition) { FactoryBot.build(:petition, state: Petition::CLOSED_STATE) }

      it "returns true" do
        expect(petition.closed?).to be_truthy
      end
    end

    context "for other states" do
      (Petition::STATES - [Petition::CLOSED_STATE]).each do |state|
        let(:petition) { FactoryBot.build(:petition, state: state) }

        it "is not open when state is #{state}" do
          expect(petition.open?).to be_falsey
        end
      end
    end
  end

  describe "#closed_for_signing?" do
    let(:now) { Time.current.change(sec: 0) }
    let(:yesterday) { now - 24.hours }

    context "when the petition is open" do
      let(:petition) { FactoryBot.create(:open_petition) }

      it "returns false" do
        expect(petition.closed_for_signing?(now)).to be_falsey
      end
    end

    context "when the petition is rejected" do
      let(:petition) { FactoryBot.create(:rejected_petition) }

      it "returns true" do
        expect(petition.closed_for_signing?(now)).to be_truthy
      end
    end

    context "when the petition closed less than 24 hours ago" do
      let(:petition) { FactoryBot.create(:closed_petition, closed_at: yesterday + 1.second) }

      it "returns false" do
        expect(petition.closed_for_signing?(now)).to be_falsey
      end
    end

    context "when the petition closed exactly 24 hours ago" do
      let(:petition) { FactoryBot.create(:closed_petition, closed_at: yesterday) }

      it "returns false" do
        expect(petition.closed_for_signing?(now)).to be_falsey
      end
    end

    context "when the petition closed more than 24 hours ago" do
      let(:petition) { FactoryBot.create(:closed_petition, closed_at: yesterday - 1.second) }

      it "returns true" do
        expect(petition.closed_for_signing?(now)).to be_truthy
      end
    end
  end

  describe "#rejected?" do
    context "when the state is rejected" do
      let(:petition) { FactoryBot.build(:petition, state: Petition::REJECTED_STATE) }

      it "returns true" do
        expect(petition.rejected?).to be_truthy
      end
    end

    context "for other states" do
      (Petition::STATES - [Petition::REJECTED_STATE]).each do |state|
        let(:petition) { FactoryBot.build(:petition, state: state) }

        it "is not rejected when state is #{state}" do
          expect(petition.rejected?).to be_falsey
        end
      end
    end
  end

  describe "#hidden?" do
    context "when the state is hidden" do
      it "returns true" do
        expect(FactoryBot.build(:petition, :state => Petition::HIDDEN_STATE).hidden?).to be_truthy
      end
    end

    context "for other states" do
      (Petition::STATES - [Petition::HIDDEN_STATE]).each do |state|
        let(:petition) { FactoryBot.build(:petition, state: state) }

        it "is not hidden when state is #{state}" do
          expect(petition.hidden?).to be_falsey
        end
      end
    end
  end

  describe "#visible?" do
    context "for moderated states" do
      Petition::VISIBLE_STATES.each do |state|
        let(:petition) { FactoryBot.build(:petition, state: state) }

        it "is visible when state is #{state}" do
          expect(petition.visible?).to be_truthy
        end
      end
    end

    context "for other states" do
      (Petition::STATES - Petition::VISIBLE_STATES).each do |state|
        let(:petition) { FactoryBot.build(:petition, state: state) }

        it "is not visible when state is #{state}" do
          expect(petition.visible?).to be_falsey
        end
      end
    end
  end

  describe "#flagged?" do
    context "when the state is flagged" do
      let(:petition) { FactoryBot.build(:petition, state: Petition::FLAGGED_STATE) }

      it "returns true" do
        expect(petition.flagged?).to be_truthy
      end
    end

    context "for other states" do
      (Petition::STATES - [Petition::FLAGGED_STATE]).each do |state|
        let(:petition) { FactoryBot.build(:petition, state: state) }

        it "is not open when state is #{state}" do
          expect(petition.flagged?).to be_falsey
        end
      end
    end
  end

  describe "#in_moderation?" do
    context "for in moderation states" do
      Petition::MODERATION_STATES.each do |state|
        let(:petition) { FactoryBot.build(:petition, state: state) }

        it "is in moderation when state is #{state}" do
          expect(petition.in_moderation?).to be_truthy
        end
      end
    end

    context "for other states" do
      (Petition::STATES - Petition::MODERATION_STATES).each do |state|
        let(:petition) { FactoryBot.build(:petition, state: state) }

        it "is not in moderation when state is #{state}" do
          expect(petition.in_moderation?).to be_falsey
        end
      end
    end
  end

  describe "#moderated?" do
    context "for moderated states" do
      Petition::MODERATED_STATES.each do |state|
        let(:petition) { FactoryBot.build(:petition, state: state) }

        it "is moderated when state is #{state}" do
          expect(petition.moderated?).to be_truthy
        end
      end
    end

    context "for other states" do
      (Petition::STATES - Petition::MODERATED_STATES).each do |state|
        let(:petition) { FactoryBot.build(:petition, state: state) }

        it "is not moderated when state is #{state}" do
          expect(petition.moderated?).to be_falsey
        end
      end
    end
  end

  describe "#in_todo_list?" do
    context "for todo list states" do
      Petition::TODO_LIST_STATES.each do |state|
        let(:petition) { FactoryBot.build(:petition, state: state) }

        it "is in todo list when the state is #{state}" do
          expect(petition.in_todo_list?).to be_truthy
        end
      end
    end

    context "for other states" do
      (Petition::STATES - Petition::TODO_LIST_STATES).each do |state|
        let(:petition) { FactoryBot.build(:petition, state: state) }

        it "is not in todo list when the state is #{state}" do
          expect(petition.in_todo_list?).to be_falsey
        end
      end
    end
  end

  describe "counting validated signatures" do
    let(:petition) { FactoryBot.build(:petition) }

    it "only counts validated signtatures" do
      expect(petition.signatures).to receive(:validated).and_return(double(:valid_signatures, :count => 123))
      expect(petition.count_validated_signatures).to eq(123)
    end
  end

  describe ".close_petitions!" do
    context "when a petition is in the open state and the closing date has not passed" do
      let(:open_at) { Site.opened_at_for_closing(1.day.from_now) }
      let!(:petition) { FactoryBot.create(:open_petition, open_at: open_at) }

      it "does not close the petition" do
        expect{
          described_class.close_petitions!
        }.not_to change{ petition.reload.state }
      end
    end

    context "when a petition is in the open state and closed_at has passed" do
      let(:open_at) { Site.opened_at_for_closing - 1.day }
      let!(:petition) { FactoryBot.create(:open_petition, referred: true, open_at: open_at, closed_at: 1.day.ago) }

      it "does close the petition" do
        expect{
          described_class.close_petitions!
        }.to change{ petition.reload.state }.from('open').to('closed')
      end
    end
  end

  describe ".in_need_of_closing" do
    context "when a petition is in the closed state" do
      let!(:petition) { FactoryBot.create(:closed_petition) }

      it "does not find the petition" do
        expect(described_class.in_need_of_closing.to_a).not_to include(petition)
      end
    end

    context "when a petition is in the open state and the closing date has not passed" do
      let!(:petition) { FactoryBot.create(:open_petition, open_at: 1.month.ago, closed_at: 1.day.from_now) }

      it "does not find the petition" do
        expect(described_class.in_need_of_closing.to_a).not_to include(petition)
      end
    end

    context "when a petition is in the open state and the closing date has passed" do
      let!(:petition) { FactoryBot.create(:open_petition, open_at: 1.month.ago, closed_at: 1.day.ago) }

      it "finds the petition" do
        expect(described_class.in_need_of_closing.to_a).to include(petition)
      end
    end
  end

  describe ".in_need_of_marking_as_debated" do
    context "when a petition is not in the the 'awaiting' debate state" do
      let!(:petition) { FactoryBot.create(:open_petition) }

      it "does not find the petition" do
        expect(described_class.in_need_of_marking_as_debated.to_a).not_to include(petition)
      end
    end

    context "when a petition is awaiting a debate date" do
      let!(:petition) {
        FactoryBot.create(:open_petition,
          debate_state: 'awaiting',
          scheduled_debate_date: nil
        )
      }

      it "does not find the petition" do
        expect(described_class.in_need_of_marking_as_debated.to_a).not_to include(petition)
      end
    end

    context "when a petition is awaiting a debate" do
      let!(:petition) {
        FactoryBot.create(:open_petition,
          debate_state: 'awaiting',
          scheduled_debate_date: 2.days.from_now
        )
      }

      it "does not find the petition" do
        expect(described_class.in_need_of_marking_as_debated.to_a).not_to include(petition)
      end
    end

    context "when a petition debate date has passed but is still marked as 'awaiting'" do
      let(:petition) {
        FactoryBot.build(:open_petition,
          debate_state: 'awaiting',
          scheduled_debate_date: Date.tomorrow
        )
      }

      before do
        travel_to(2.days.ago) do
          petition.save
        end
      end

      it "finds the petition" do
        expect(described_class.in_need_of_marking_as_debated.to_a).to include(petition)
      end
    end

    context "when a petition debate date has passed and it marked as 'debated'" do
      let!(:petition) {
        FactoryBot.create(:open_petition,
          debate_state: 'debated',
          scheduled_debate_date: 2.days.ago
        )
      }

      it "does not find the petition" do
        expect(described_class.in_need_of_marking_as_debated.to_a).not_to include(petition)
      end
    end
  end

  describe ".mark_petitions_as_debated!" do
    context "when a petition is in the scheduled debate state and the debate date has passed" do
      let(:petition) {
        FactoryBot.build(:open_petition,
          debate_state: 'scheduled',
          scheduled_debate_date: Date.tomorrow
        )
      }

      before do
        travel_to(2.days.ago) do
          petition.save
        end
      end

      it "marks the petition as debated" do
        expect{
          described_class.mark_petitions_as_debated!
        }.to change{ petition.reload.debate_state }.from('scheduled').to('debated')
      end
    end

    context "when a petition is in the scheduled debate state and the debate date has not passed" do
      let(:petition) {
        FactoryBot.build(:open_petition,
          debate_state: 'scheduled',
          scheduled_debate_date: Date.tomorrow
        )
      }

      before do
        petition.save
      end

      it "does not mark the petition as debated" do
        expect{
          described_class.mark_petitions_as_debated!
        }.not_to change{ petition.reload.debate_state }
      end
    end
  end

  describe "#update_signature_count!" do
    let!(:petition) { FactoryBot.create(:open_petition, attributes) }

    context "when there are petitions with invalid signature counts" do
      let(:attributes) { { created_at: 2.days.ago, updated_at: 2.days.ago, signature_count: 100 } }

      it "updates the signature count" do
        expect{
          petition.update_signature_count!
        }.to change{ petition.reload.signature_count }.from(100).to(1)
      end

      it "updates the updated_at timestamp" do
        expect{
          petition.update_signature_count!
        }.to change{ petition.reload.updated_at }.to(be_within(1.second).of(Time.current))
      end
    end
  end

  describe "#increment_signature_count!" do
    let(:signature_count) { 8 }
    let(:debate_state) { 'pending' }

    let(:petition) do
      FactoryBot.create(:open_petition, {
        debate_state: debate_state,
        signature_count: signature_count,
        last_signed_at: 2.days.ago,
        updated_at: 2.days.ago,
        creator_attributes: { validated_at: 5.days.ago }
      })
    end

    context "when there is one more signature" do
      before do
        FactoryBot.create(:validated_signature, petition: petition, increment: false)
      end

      it "increases the signature count by 1" do
        expect{
          petition.increment_signature_count!
        }.to change{ petition.signature_count }.by(1)
      end

      it "updates the last_signed_at timestamp" do
        petition.increment_signature_count!
        expect(petition.last_signed_at).to be_within(1.second).of(Time.current)
      end

      it "updates the updated_at timestamp" do
        petition.increment_signature_count!
        expect(petition.updated_at).to be_within(1.second).of(Time.current)
      end
    end

    context "when there is more than one signature" do
      before do
        5.times do
          FactoryBot.create(:validated_signature, petition: petition, increment: false)
        end
      end

      it "increases the signature count by 5" do
        expect{
          petition.increment_signature_count!
        }.to change{ petition.signature_count }.by(5)
      end

      it "updates the last_signed_at timestamp" do
        petition.increment_signature_count!
        expect(petition.last_signed_at).to be_within(1.second).of(Time.current)
      end

      it "updates the updated_at timestamp" do
        petition.increment_signature_count!
        expect(petition.updated_at).to be_within(1.second).of(Time.current)
      end
    end

    context "when the petition is first sponsored" do
      let(:petition) do
        FactoryBot.create(:petition, {
          state: "pending",
          signature_count: 0,
          last_signed_at: nil,
          updated_at: 2.days.ago,
          increment: false
        })
      end

      before do
        FactoryBot.create(:validated_signature, petition: petition, sponsor: true, increment: false)
      end

      it "records changes the state from 'pending' to 'validated'" do
        expect {
          petition.increment_signature_count!
        }.to change{
          petition.state
        }.from(Petition::PENDING_STATE).to(Petition::VALIDATED_STATE)
      end
    end

    context "when the signature count crosses the threshold for moderation" do
      let(:signature_count) { 5 }

      before do
        expect(Site).to receive(:threshold_for_moderation).and_return(5)
        FactoryBot.create(:validated_signature, petition: petition, increment: false)
      end

      context "having already been validated by a sponsor" do
        let(:petition) do
          FactoryBot.create(:validated_petition, {
            signature_count: signature_count,
            last_signed_at: 2.days.ago,
            updated_at: 2.days.ago
          })
        end

        it "records the time it happened" do
          expect {
            petition.increment_signature_count!
          }.to change {
            petition.moderation_threshold_reached_at
          }.to be_within(1.second).of(Time.current)
        end

        it "records changes the state from 'validated' to 'sponsored'" do
          expect {
            petition.increment_signature_count!
          }.to change {
            petition.state
          }.from(Petition::VALIDATED_STATE).to(Petition::SPONSORED_STATE)
        end
      end

      context "without having been validated by a sponsor yet" do
        let(:petition) do
          FactoryBot.create(:pending_petition, {
            signature_count: signature_count,
            last_signed_at: 2.days.ago,
            updated_at: 2.days.ago
          })
        end

        it "records the time it happened" do
          expect {
            petition.increment_signature_count!
          }.to change {
            petition.moderation_threshold_reached_at
          }.to be_within(1.second).of(Time.current)
        end

        it "records changes the state from 'validated' to 'sponsored'" do
          expect {
            petition.increment_signature_count!
          }.to change {
            petition.state
          }.from(Petition::PENDING_STATE).to(Petition::SPONSORED_STATE)
        end
      end
    end

    context "when the signature count is higher than the threshold for moderation" do
      let(:signature_count) { 100 }

      before do
        FactoryBot.create(:validated_signature, petition: petition, increment: false)
      end

      context "and moderation_threshold_reached_at is nil" do
        let(:petition) do
          FactoryBot.create(:open_petition, {
            signature_count: signature_count,
            last_signed_at: 2.days.ago,
            updated_at: 2.days.ago,
            moderation_threshold_reached_at: nil
          })
        end

        it "doesn't change the state to sponsored" do
          expect {
            petition.increment_signature_count!
          }.not_to change { petition.state }
        end

        it "doesn't update the moderation_threshold_reached_at column" do
          expect {
            petition.increment_signature_count!
          }.not_to change { petition.moderation_threshold_reached_at }
        end
      end
    end

    context "when the petition hasn't been debated" do
      let(:debate_state) { "pending" }

      context "when the signature count crosses the threshold for a debate" do
        let(:signature_count) { 99 }

        before do
          expect(Site).to receive(:threshold_for_debate).and_return(100)
          FactoryBot.create(:validated_signature, petition: petition, increment: false)
        end

        it "records the time it happened" do
          expect {
            petition.increment_signature_count!
          }.to change {
            petition.debate_threshold_reached_at
          }.to be_within(1.second).of(Time.current)
        end

        it "sets the debate_state to 'awaiting'" do
          expect {
            petition.increment_signature_count!
          }.to change {
            petition.debate_state
          }.from("pending").to("awaiting")
        end
      end
    end

    context "when the petition is awaiting a debate" do
      let(:debate_state) { "awaiting" }

      context "when the signature count crosses the threshold for a debate" do
        let(:signature_count) { 99 }

        before do
          expect(Site).to receive(:threshold_for_debate).and_return(100)
          FactoryBot.create(:validated_signature, petition: petition, increment: false)
        end

        it "records the time it happened" do
          expect {
            petition.increment_signature_count!
          }.to change {
            petition.debate_threshold_reached_at
          }.to be_within(1.second).of(Time.current)
        end

        it "doesn't change debate_state" do
          expect {
            petition.increment_signature_count!
          }.not_to change {
            petition.debate_state
          }.from("awaiting")
        end
      end
    end

    context "when the petition has been debated" do
      let(:debate_state) { "debated" }

      context "when the signature count crosses the threshold for a debate" do
        let(:signature_count) { 99 }

        before do
          expect(Site).to receive(:threshold_for_debate).and_return(100)
          FactoryBot.create(:validated_signature, petition: petition, increment: false)
        end

        it "records the time it happened" do
          expect {
            petition.increment_signature_count!
          }.to change {
            petition.debate_threshold_reached_at
          }.to be_within(1.second).of(Time.current)
        end

        it "doesn't change debate_state" do
          expect {
            petition.increment_signature_count!
          }.not_to change {
            petition.debate_state
          }.from("debated")
        end
      end
    end

    context "when thresholds are disabled" do
      before do
        Site.instance.update! feature_flags: { disable_thresholds_and_debates: true }
      end

      context "and the signature count crosses the threshold for a debate" do
        let(:signature_count) { 99 }

        before do
          expect(Site).not_to receive(:threshold_for_debate)
          FactoryBot.create(:validated_signature, petition: petition, increment: false)
        end

        it "doesn't record the time it happened" do
          expect {
            petition.increment_signature_count!
          }.not_to change {
            petition.debate_threshold_reached_at
          }.from(nil)
        end

        it "doesn't set the debate_state to 'awaiting'" do
          expect {
            petition.increment_signature_count!
          }.not_to change {
            petition.debate_state
          }.from("pending")
        end
      end
    end
  end

  describe "#decrement_signature_count!" do
    let(:signature_count) { 8 }
    let(:debate_state) { 'awaiting' }

    let(:petition) do
      FactoryBot.create(:open_petition, {
        signature_count: signature_count,
        last_signed_at: 2.days.ago,
        updated_at: 2.days.ago,
        referral_threshold_reached_at: 2.days.ago,
        debate_threshold_reached_at: 2.days.ago,
        debate_state: debate_state
      })
    end

    it "decreases the signature count by 1" do
      expect{
        petition.decrement_signature_count!
      }.to change{ petition.signature_count }.by(-1)
    end

    it "updates the updated_at timestamp" do
      petition.decrement_signature_count!
      expect(petition.updated_at).to be_within(1.second).of(Time.current)
    end

    context "when the signature count is 1" do
      let(:signature_count) { 1 }

      it "does nothing" do
        expect{
          petition.decrement_signature_count!
        }.not_to change{ petition.signature_count }
      end
    end

    context "when the signature count crosses below the threshold for a response" do
      let(:signature_count) { 10 }

      before do
        expect(Site).to receive(:threshold_for_referral).and_return(10)
      end

      it "resets the timestamp" do
        petition.decrement_signature_count!
        expect(petition.referral_threshold_reached_at).to be_nil
      end
    end

    context "when the signature count crosses below the threshold for a debate" do
      let(:signature_count) { 100 }

      before do
        expect(Site).to receive(:threshold_for_debate).and_return(100)
      end

      it "resets the timestamp" do
        petition.decrement_signature_count!
        expect(petition.debate_threshold_reached_at).to be_nil
      end

      context "and a debate has not been scheduled" do
        let(:debate_state) { "awaiting" }

        it "sets the debate_state to 'pending'" do
          petition.decrement_signature_count!
          expect(petition.debate_state).to eq("pending")
        end
      end

      context "and a debate has been scheduled" do
        let(:debate_state) { "scheduled" }

        it "doesn't change debated_state" do
          expect {
            petition.decrement_signature_count!
          }.not_to change {
            petition.debate_state
          }.from("scheduled")
        end
      end

      context "and a debate has taken place" do
        let(:debate_state) { "debated" }

        it "doesn't change debated_state" do
          expect {
            petition.decrement_signature_count!
          }.not_to change {
            petition.debate_state
          }.from("debated")
        end
      end

      context "and a debate has not taken place" do
        let(:debate_state) { "not_debated" }

        it "doesn't change debated_state" do
          expect {
            petition.decrement_signature_count!
          }.not_to change {
            petition.debate_state
          }.from("not_debated")
        end
      end
    end
  end

  describe "will_reach_threshold_for_moderation?" do
    context "when moderation_threshold_reached_at is not present" do
      let(:petition) { FactoryBot.create(:validated_petition, signature_count: signature_count) }

      before do
        expect(Site).to receive(:threshold_for_moderation).and_return(5)
      end

      context "and the signature count is less than the threshold" do
        let(:signature_count) { 4 }

        it "is falsey" do
          expect(petition.will_reach_threshold_for_moderation?).to be_falsey
        end
      end

      context "and the signature count is one less than the threshold" do
        let(:signature_count) { 5 }

        it "is truthy" do
          expect(petition.will_reach_threshold_for_moderation?).to be_truthy
        end
      end

      context "and the signature count is more than the threshold" do
        let(:signature_count) { 6 }

        it "is truthy" do
          expect(petition.will_reach_threshold_for_moderation?).to be_truthy
        end
      end
    end

    context "when moderation_threshold_reached_at is present" do
      let(:petition) { FactoryBot.create(:sponsored_petition) }

      before do
        expect(Site).not_to receive(:threshold_for_moderation)
      end

      it "is falsey" do
        expect(petition.will_reach_threshold_for_moderation?).to be_falsey
      end
    end
  end

  describe "at_threshold_for_moderation?" do
    context "when moderation_threshold_reached_at is not present" do
      let(:petition) { FactoryBot.create(:validated_petition, signature_count: signature_count) }

      before do
        expect(Site).to receive(:threshold_for_moderation).and_return(5)
      end

      context "and the signature count is less than the threshold" do
        let(:signature_count) { 5 }

        it "is falsey" do
          expect(petition.at_threshold_for_moderation?).to be_falsey
        end
      end

      context "and the signature count is equal than the threshold" do
        let(:signature_count) { 6 }

        it "is truthy" do
          expect(petition.at_threshold_for_moderation?).to be_truthy
        end
      end

      context "and the signature count is more than the threshold" do
        let(:signature_count) { 7 }

        it "is truthy" do
          expect(petition.at_threshold_for_moderation?).to be_truthy
        end
      end
    end

    context "when moderation_threshold_reached_at is present" do
      let(:petition) { FactoryBot.create(:sponsored_petition) }

      before do
        expect(Site).not_to receive(:threshold_for_moderation)
      end

      it "is falsey" do
        expect(petition.at_threshold_for_moderation?).to be_falsey
      end
    end

    context "when the petition is not collecting signatures" do
      let(:petition) { FactoryBot.create(:pending_petition, signature_count: signature_count, collect_signatures: false) }

      before do
        expect(Site).to receive(:threshold_for_moderation).and_return(0)
      end

      context "and the signature count is less than the threshold" do
        let(:signature_count) { 0 }

        it "is falsey" do
          expect(petition.at_threshold_for_moderation?).to be_falsey
        end
      end

      context "and the signature count is equal to the threshold" do
        let(:signature_count) { 1 }

        it "is truthy" do
          expect(petition.at_threshold_for_moderation?).to be_truthy
        end
      end

      context "and the signature count is more than the threshold" do
        let(:signature_count) { 2 }

        it "is truthy" do
          expect(petition.at_threshold_for_moderation?).to be_truthy
        end
      end
    end
  end

  describe "at_threshold_for_referral?" do
    context "when referral_threshold_reached_at is not present" do
      let(:petition) { FactoryBot.create(:open_petition, signature_count: signature_count, referred: false) }

      before do
        expect(Site).to receive(:threshold_for_referral).and_return(10)
      end

      context "and the signature count is 2 or more less than the threshold" do
        let(:signature_count) { 8 }

        it "is falsey" do
          expect(petition.at_threshold_for_referral?).to be_falsey
        end
      end

      context "and the signature count is 1 less than the threshold" do
        let(:signature_count) { 9 }

        it "is falsey" do
          expect(petition.at_threshold_for_referral?).to be_falsey
        end
      end

      context "and the signature count equal to the threshold" do
        let(:signature_count) { 10 }

        it "is truthy" do
          expect(petition.at_threshold_for_referral?).to be_truthy
        end
      end

      context "and the signature count is more than the threshold" do
        let(:signature_count) { 10 }

        it "is truthy" do
          expect(petition.at_threshold_for_referral?).to be_truthy
        end
      end
    end

    context "when referral_threshold_reached_at is present" do
      let(:petition) { FactoryBot.create(:referred_petition) }

      before do
        expect(Site).not_to receive(:threshold_for_referral)
      end

      it "is falsey" do
        expect(petition.at_threshold_for_referral?).to be_falsey
      end
    end
  end

  describe 'at_threshold_for_debate?' do
    let(:petition) { FactoryBot.create(:petition, signature_count: signature_count) }

    context 'when signature count is 1 less than the threshold' do
      let(:signature_count) { Site.threshold_for_debate - 1 }

      it 'is falsey' do
        expect(petition.at_threshold_for_debate?).to be_falsey
      end
    end

    context 'when signature count is equal to the threshold' do
      let(:signature_count) { Site.threshold_for_debate }

      it 'is truthy' do
        expect(petition.at_threshold_for_debate?).to be_truthy
      end
    end

    context 'when signature count is 1 or more than the threshold' do
      let(:signature_count) { Site.threshold_for_debate + 1 }

      it 'is truthy' do
        expect(petition.at_threshold_for_debate?).to be_truthy
      end
    end

    context 'when signature count is 2 or more less than the threshold' do
      let(:signature_count) { Site.threshold_for_debate - 2 }

      it 'is falsey' do
        expect(petition.at_threshold_for_debate?).to be_falsey
      end
    end

    context 'when the debate_threshold_reached_at is present' do
      let(:petition) { FactoryBot.create(:awaiting_debate_petition) }

      it 'is falsey' do
        expect(petition.at_threshold_for_debate?).to be_falsey
      end
    end
  end

  describe '#moderate' do
    shared_examples "it doesn't change timestamps" do
      it "doesn't change the open_at timestamp" do
        expect {
          petition.moderate(params)
        }.not_to change {
          petition.reload.open_at
        }
      end

      it "doesn't change the closed_at timestamp" do
        expect {
          petition.moderate(moderation: "approve")
        }.not_to change {
          petition.reload.closed_at
        }
      end
    end

    context "when taking down an open petition" do
      let(:petition) do
        FactoryBot.create(
          :open_petition,
          open_at: 2.weeks.ago,
          closed_at: 2.weeks.from_now,
          collect_signatures: true
        )
      end

      let(:params) do
        { moderation: "reject", rejection: { code: "duplicate" } }
      end

      it_behaves_like "it doesn't change timestamps"
    end

    context "when republishing a closed petition that was taken down" do
      let(:params) do
        { moderation: "approve" }
      end

      context "and the petition collected signatures" do
        let(:petition) do
          FactoryBot.create(
            :rejected_petition,
            :translated,
            open_at: 6.weeks.ago,
            closed_at: 2.weeks.ago,
            collect_signatures: true
          )
        end

        it_behaves_like "it doesn't change timestamps"

        it "restores it to the 'closed' state" do
          expect {
            petition.moderate(params)
          }.to change {
            petition.reload.state
          }.from('rejected').to('closed')
        end
      end

      context "and the petition didn't collect signatures" do
        let(:petition) do
          FactoryBot.create(
            :rejected_petition,
            :translated,
            open_at: 6.weeks.ago,
            closed_at: 2.weeks.ago,
            collect_signatures: false
          )
        end

        it_behaves_like "it doesn't change timestamps"

        it "restores it to the 'closed' state" do
          expect {
            petition.moderate(params)
          }.to change {
            petition.reload.state
          }.from('rejected').to('closed')
        end
      end
    end

    context "when republishing an open petition that was taken down" do
      let(:params) do
        { moderation: "approve" }
      end

      let(:petition) do
        FactoryBot.create(
          :rejected_petition,
          :translated,
          open_at: 2.weeks.ago,
          closed_at: 2.weeks.from_now,
          collect_signatures: true
        )
      end

      it_behaves_like "it doesn't change timestamps"

      it "restores it to the 'open' state" do
        expect {
          petition.moderate(params)
        }.to change {
          petition.reload.state
        }.from('rejected').to('open')
      end
    end
  end

  describe '#publish' do
    let(:now) { Time.current }
    let(:duration) { Site.petition_duration.weeks }
    let(:closing_date) { (now + duration).end_of_day }

    context "when the petition is collecting signatures" do
      subject(:petition) { FactoryBot.create(:sponsored_petition, :translated, collect_signatures: true) }

      before do
        petition.publish!
      end

      it "sets the state to OPEN" do
        expect(petition.state).to eq(Petition::OPEN_STATE)
      end

      it "sets the open date to now" do
        expect(petition.open_at).to be_within(1.second).of(now)
      end

      it "does not set the closed date" do
        expect(petition.closed_at).to be_nil
      end
    end

    context "when the petition is not collecting signatures" do
      subject(:petition) { FactoryBot.create(:sponsored_petition, :translated, collect_signatures: false) }

      before do
        Site.instance.update!(
          minimum_number_of_sponsors: 0,
          threshold_for_moderation: 0,
          threshold_for_referral: 1
        )

        petition.publish!
      end

      it "sets the state to CLOSED" do
        expect(petition.state).to eq(Petition::CLOSED_STATE)
      end

      it "does not set the closed date" do
        expect(petition.closed_at).to be_nil
      end
    end

    context "when thresholds are disabled" do
      before do
        Site.instance.update! feature_flags: { disable_thresholds_and_debates: true }
      end

      context "and the petition is not collecting signatures" do
        subject(:petition) { FactoryBot.create(:sponsored_petition, :translated, collect_signatures: false) }

        before do
          petition.publish!
        end

        it "sets the state to CLOSED" do
          expect(petition.state).to eq(Petition::CLOSED_STATE)
        end

        it "does not set the closed date" do
          expect(petition.closed_at).to be_nil
        end

        it "sets the referred date" do
          expect(petition.referred_at).to be_within(1.second).of(Time.now)
        end
      end
    end
  end

  describe "#reject!" do
    subject(:petition) { FactoryBot.create(:petition, :translated) }

    %w[insufficient duplicate irrelevant no-action fake-name].each do |rejection_code|
      context "when the reason for rejection is #{rejection_code}" do
        before do
          petition.reject!(code: rejection_code)
          petition.reload
        end

        it "sets rejection.code to '#{rejection_code}'" do
          expect(petition.rejection.code).to eq(rejection_code)
        end

        it "sets Petition#state to 'rejected'" do
          expect(petition.state).to eq("rejected")
        end
      end
    end

    %w[libellous offensive not-suitable].each do |rejection_code|
      context "when the reason for rejection is #{rejection_code}" do
        before do
          petition.reject!(code: rejection_code)
          petition.reload
        end

        it "sets rejection.code to '#{rejection_code}'" do
          expect(petition.rejection.code).to eq(rejection_code)
        end

        it "sets Petition#state to 'hidden'" do
          expect(petition.state).to eq("hidden")
        end
      end
    end

    context "when two moderators reject the petition at the same time" do
      let(:rejection) { petition.reload.rejection }

      it "doesn't raise an ActiveRecord::RecordNotUnique error" do
        expect {
          p1 = described_class.find(petition.id)
          p2 = described_class.find(petition.id)

          expect(p1.rejection).to be_nil
          expect(p1.association(:rejection)).to be_loaded

          expect(p2.rejection).to be_nil
          expect(p2.association(:rejection)).to be_loaded

          p1.reject!(code: "duplicate")
          p2.reject!(code: "irrelevant")

          expect(rejection.code).to eq("irrelevant")
        }.not_to raise_error
      end
    end
  end

  describe '#close!' do
    let(:time) { Time.current }
    let(:debate_state) { 'pending' }
    subject(:petition) { FactoryBot.create(:open_petition, debate_state: debate_state) }

    context "when the petition is open" do
      it "sets the state to CLOSED" do
        expect {
          petition.close!(time)
        }.to change {
          petition.state
        }.from(Petition::OPEN_STATE).to(Petition::CLOSED_STATE)
      end

      it "changes the closing date" do
        expect {
          petition.close!(time)
        }.to change {
          petition.closed_at
        }.to be_within(1.second).of(time)
      end
    end

    %w[pending awaiting scheduled debated not_debated].each do |state|
      context "when the debate state is '#{state}'" do
        let(:debate_state) { state }

        it "doesn't change the debate state" do
          expect {
            petition.close!(time)
          }.not_to change {
            petition.debate_state
          }
        end
      end
    end

    (Petition::STATES - [Petition::OPEN_STATE]).each do |state|
      context "when called on a #{state} petition" do
        subject(:petition) { FactoryBot.create(:"#{state}_petition") }

        it "raises a RuntimeError" do
          expect { petition.close!(time) }.to raise_error(RuntimeError)
        end
      end
    end
  end

  describe "#validate_creator!" do
    let(:petition) { FactoryBot.create(:pending_petition, attributes) }
    let(:signature) { petition.creator }
    let(:now) { Time.current }

    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    let(:attributes) do
      { created_at: 2.days.ago, updated_at: 2.days.ago }
    end

    it "changes creator signature state to validated" do
      expect {
        petition.validate_creator!
      }.to change { signature.reload.validated? }.from(false).to(true)
    end

    it "increments the signature count" do
      expect {
        petition.validate_creator!
      }.to change { petition.signature_count }.by(1)
    end

    it "timestamps the petition to say it was updated before now" do
      petition.validate_creator!(now)
      expect(petition.updated_at).to be < Time.current
    end

    it "timestamps the petition to say it was last signed at before now" do
      petition.validate_creator!
      expect(petition.last_signed_at).to be < Time.current
    end
  end

  describe '#has_maximum_sponsors?' do
    %w[pending validated sponsored flagged].each do |state|
      let(:petition) { FactoryBot.create(:"#{state}_petition", sponsor_count: sponor_count, sponsors_signed: sponsors_signed) }

      context "when petition is #{state}" do
        context "and has less than the maximum number of sponsors" do
          let(:sponor_count) { Site.maximum_number_of_sponsors - 1 }
          let(:sponsors_signed) { true }

          it "returns false" do
            expect(petition.has_maximum_sponsors?).to eq(false)
          end
        end

        context "and has the maximum number of sponsors, but none have signed" do
          let(:sponor_count) { Site.maximum_number_of_sponsors }
          let(:sponsors_signed) { false }

          it "returns false" do
            expect(petition.has_maximum_sponsors?).to eq(false)
          end
        end

        context "and has more than the maximum number of sponsors, but none have signed" do
          let(:sponor_count) { Site.maximum_number_of_sponsors + 1 }
          let(:sponsors_signed) { false }

          it "returns false" do
            expect(petition.has_maximum_sponsors?).to eq(false)
          end
        end

        context "and has the maximum number of sponsors and they have signed" do
          let(:sponor_count) { Site.maximum_number_of_sponsors }
          let(:sponsors_signed) { true }

          it "returns true" do
            expect(petition.has_maximum_sponsors?).to eq(true)
          end
        end

        context "and has more than the maximum number of sponsors and they have signed" do
          let(:sponor_count) { Site.maximum_number_of_sponsors + 1 }
          let(:sponsors_signed) { true }

          it "returns true" do
            expect(petition.has_maximum_sponsors?).to eq(true)
          end
        end
      end
    end
  end

  describe 'email requested receipts' do
    it { is_expected.to have_one(:email_requested_receipt).dependent(:destroy) }

    describe '#email_requested_receipt!' do
      let(:petition) { FactoryBot.create(:petition) }

      it 'returns the existing db object if one exists' do
        existing = petition.create_email_requested_receipt
        expect(petition.email_requested_receipt!).to eq existing
      end

      it 'returns a newly created instance if does not already exist' do
        instance = petition.email_requested_receipt!
        expect(instance).to be_present
        expect(instance).to be_a(EmailRequestedReceipt)
        expect(instance.petition).to eq petition
        expect(instance.petition).to be_persisted
      end
    end
  end

  describe '#get_email_requested_at_for' do
    let(:petition) { FactoryBot.create(:open_petition) }
    let(:receipt) { petition.email_requested_receipt! }
    let(:the_stored_time) { 6.days.ago }

    it 'returns nil when nothing has been stamped for the supplied name' do
      expect(petition.get_email_requested_at_for('petition_email')).to be_nil
    end

    it 'returns the stored timestamp for the supplied name' do
      receipt.update_column('petition_email', the_stored_time)
      expect(petition.get_email_requested_at_for('petition_email')).to eq the_stored_time
    end
  end

  describe '#set_email_requested_at_for' do
    let(:petition) { FactoryBot.create(:open_petition) }
    let(:receipt) { petition.email_requested_receipt! }
    let(:the_stored_time) { 6.days.ago }

    it 'sets the stored timestamp for the supplied name to the supplied time' do
      petition.set_email_requested_at_for('petition_email', to: the_stored_time)
      expect(receipt.petition_email).to eq the_stored_time
    end

    it 'sets the stored timestamp for the supplied name to the current time if none is supplied' do
      travel_to the_stored_time do
        petition.set_email_requested_at_for('petition_email')
        expect(receipt.petition_email).to eq Time.current
      end
    end
  end

  describe "#signatures_to_email_for" do
    let!(:petition) { FactoryBot.create(:open_petition) }
    let!(:creator) { petition.creator }
    let!(:other_signature) { FactoryBot.create(:validated_signature, petition: petition) }
    let(:petition_timestamp) { 5.days.ago }

    before { petition.set_email_requested_at_for('petition_email', to: petition_timestamp) }

    it 'raises an error if the petition does not have an email requested receipt' do
      petition.email_requested_receipt.destroy && petition.reload
      expect { petition.signatures_to_email_for('petition_email') }.to raise_error ArgumentError
    end

    it 'raises an error if the petition does not have the requested timestamp in its email requested receipt' do
      petition.email_requested_receipt.update_column('petition_email', nil)
      expect { petition.signatures_to_email_for('petition_email') }.to raise_error ArgumentError
    end

    it "does not return those that do not want to be emailed" do
      petition.creator.update_attribute(:notify_by_email, false)
      expect(petition.signatures_to_email_for('petition_email')).not_to include creator
    end

    it 'does not return unvalidated signatures' do
      other_signature.update_column(:state, Signature::PENDING_STATE)
      expect(petition.signatures_to_email_for('petition_email')).not_to include other_signature
    end

    it 'does not return signatures that have a sent timestamp newer than the petitions requested receipt' do
      other_signature.set_email_sent_at_for('petition_email', to: petition_timestamp + 1.day)
      expect(petition.signatures_to_email_for('petition_email')).not_to include other_signature
    end

    it 'does not return signatures that have a sent timestamp equal to the petitions requested receipt' do
      other_signature.set_email_sent_at_for('petition_email', to: petition_timestamp)
      expect(petition.signatures_to_email_for('petition_email')).not_to include other_signature
    end

    it 'does return signatures that have a sent timestamp older than the petitions requested receipt' do
      other_signature.set_email_sent_at_for('petition_email', to: petition_timestamp - 1.day)
      expect(petition.signatures_to_email_for('petition_email')).to include other_signature
    end

    it 'returns signatures that have no sent timestamp, or null for the requested timestamp in their receipt' do
      expect(petition.signatures_to_email_for('petition_email')).to match_array [creator, other_signature]
    end
  end

  describe "#fraudulent_domains" do
    let(:petition) { FactoryBot.create(:open_petition) }
    let(:signatures) { double(:signatures) }

    let(:domains) do
      { "foo.com" => 2, "bar.com" => 1 }
    end

    before do
      allow(petition).to receive(:signatures).and_return(signatures)
    end

    it "delegates to signatures association and caches the result" do
      expect(signatures).to receive(:fraudulent_domains).once.and_return(domains)
      expect(petition.fraudulent_domains).to eq("foo.com" => 2, "bar.com" => 1)
      expect(petition.fraudulent_domains).to eq("foo.com" => 2, "bar.com" => 1)
    end
  end

  describe "#fraudulent_domains?" do
    let(:petition) { FactoryBot.create(:open_petition) }

    context "when there no fraudulent signatures" do
      it "returns false" do
        expect(petition.fraudulent_domains?).to eq(false)
      end
    end

    context "when there are fraudulent signatures" do
      before do
        FactoryBot.create(:fraudulent_signature, email: "alice@foo.com", petition: petition)
      end

      it "returns true" do
        expect(petition.fraudulent_domains?).to eq(true)
      end
    end
  end

  describe "#update_lock!" do
    let(:current_user) { FactoryBot.create(:moderator_user) }

    context "when the petition is not locked" do
      let(:petition) { FactoryBot.create(:petition, locked_by: nil, locked_at: nil) }

      it "doesn't update the locked_by association" do
        expect {
          petition.update_lock!(current_user)
        }.not_to change {
          petition.reload.locked_by
        }
      end

      it "doesn't update the locked_at timestamp" do
        expect {
          petition.update_lock!(current_user)
        }.not_to change {
          petition.reload.locked_at
        }
      end
    end

    context "when the petition is locked by someone else" do
      let(:other_user) { FactoryBot.create(:moderator_user) }
      let(:petition) { FactoryBot.create(:petition, locked_by: other_user, locked_at: 1.hour.ago) }

      it "doesn't update the locked_by association" do
        expect {
          petition.update_lock!(current_user)
        }.not_to change {
          petition.reload.locked_by
        }
      end

      it "doesn't update the locked_at timestamp" do
        expect {
          petition.update_lock!(current_user)
        }.not_to change {
          petition.reload.locked_at
        }
      end
    end

    context "when the petition is locked by the current user" do
      let(:petition) { FactoryBot.create(:petition, locked_by: current_user, locked_at: 1.hour.ago) }

      it "doesn't update the locked_by association" do
        expect {
          petition.update_lock!(current_user)
        }.not_to change {
          petition.reload.locked_by
        }
      end

      it "updates the locked_at timestamp" do
        expect {
          petition.update_lock!(current_user)
        }.to change {
          petition.reload.locked_at
        }.to be_within(1.second).of(Time.current)
      end
    end
  end

  describe "#checkout!" do
    let(:current_user) { FactoryBot.create(:moderator_user) }

    context "when the petition is not locked" do
      let(:petition) { FactoryBot.create(:petition, locked_by: nil, locked_at: nil) }

      it "updates the locked_by association" do
        expect {
          petition.checkout!(current_user)
        }.to change {
          petition.reload.locked_by
        }.from(nil).to(current_user)
      end

      it "updates the locked_at timestamp" do
        expect {
          petition.checkout!(current_user)
        }.to change {
          petition.reload.locked_at
        }.from(nil).to(be_within(1.second).of(Time.current))
      end
    end

    context "when the petition is locked by someone else" do
      let(:other_user) { FactoryBot.create(:moderator_user) }
      let(:petition) { FactoryBot.create(:petition, locked_by: other_user, locked_at: 1.hour.ago) }

      it "returns false" do
        expect(petition.checkout!(current_user)).to eq(false)
      end
    end

    context "when the petition is locked by the current user" do
      let(:petition) { FactoryBot.create(:petition, locked_by: current_user, locked_at: 1.hour.ago) }

      it "doesn't update the locked_by association" do
        expect {
          petition.checkout!(current_user)
        }.not_to change {
          petition.reload.locked_by
        }
      end

      it "updates the locked_at timestamp" do
        expect {
          petition.checkout!(current_user)
        }.to change {
          petition.reload.locked_at
        }.to be_within(1.second).of(Time.current)
      end
    end
  end

  describe "#force_checkout!" do
    let(:current_user) { FactoryBot.create(:moderator_user) }

    context "when the petition is not locked" do
      let(:petition) { FactoryBot.create(:petition, locked_by: nil, locked_at: nil) }

      it "updates the locked_by association" do
        expect {
          petition.force_checkout!(current_user)
        }.to change {
          petition.reload.locked_by
        }.from(nil).to(current_user)
      end

      it "updates the locked_at timestamp" do
        expect {
          petition.force_checkout!(current_user)
        }.to change {
          petition.reload.locked_at
        }.from(nil).to(be_within(1.second).of(Time.current))
      end
    end

    context "when the petition is locked by someone else" do
      let(:other_user) { FactoryBot.create(:moderator_user) }
      let(:petition) { FactoryBot.create(:petition, locked_by: other_user, locked_at: 1.hour.ago) }

      it "updates the locked_by association" do
        expect {
          petition.force_checkout!(current_user)
        }.to change {
          petition.reload.locked_by
        }.from(other_user).to(current_user)
      end

      it "updates the locked_at timestamp" do
        expect {
          petition.force_checkout!(current_user)
        }.to change {
          petition.reload.locked_at
        }.to(be_within(1.second).of(Time.current))
      end
    end

    context "when the petition is locked by the current user" do
      let(:petition) { FactoryBot.create(:petition, locked_by: current_user, locked_at: 1.hour.ago) }

      it "doesn't update the locked_by association" do
        expect {
          petition.force_checkout!(current_user)
        }.not_to change {
          petition.reload.locked_by
        }
      end

      it "updates the locked_at timestamp" do
        expect {
          petition.force_checkout!(current_user)
        }.to change {
          petition.reload.locked_at
        }.to be_within(1.second).of(Time.current)
      end
    end
  end

  describe "#release!" do
    let(:current_user) { FactoryBot.create(:moderator_user) }

    context "when the petition is not locked" do
      let(:petition) { FactoryBot.create(:petition, locked_by: nil, locked_at: nil) }

      it "doesn't update the locked_by association" do
        expect {
          petition.release!(current_user)
        }.not_to change {
          petition.reload.locked_by
        }
      end

      it "doesn't update the locked_at timestamp" do
        expect {
          petition.release!(current_user)
        }.not_to change {
          petition.reload.locked_at
        }
      end
    end

    context "when the petition is locked by someone else" do
      let(:other_user) { FactoryBot.create(:moderator_user) }
      let(:petition) { FactoryBot.create(:petition, locked_by: other_user, locked_at: 1.hour.ago) }

      it "doesn't update the locked_by association" do
        expect {
          petition.release!(current_user)
        }.not_to change {
          petition.reload.locked_by
        }
      end

      it "doesn't update the locked_at timestamp" do
        expect {
          petition.release!(current_user)
        }.not_to change {
          petition.reload.locked_at
        }
      end
    end

    context "when the petition is locked by the current user" do
      let(:petition) { FactoryBot.create(:petition, locked_by: current_user, locked_at: 1.hour.ago) }

      it "updates the locked_by association" do
        expect {
          petition.release!(current_user)
        }.to change {
          petition.reload.locked_by
        }.from(current_user).to(nil)
      end

      it "updates the locked_at timestamp" do
        expect {
          petition.release!(current_user)
        }.to change {
          petition.reload.locked_at
        }.to be_nil
      end
    end
  end

  describe "#locale" do
    specify do
      I18n.with_locale(:"en-GB") { expect(Petition.new.locale).to eq("en-GB") }
      I18n.with_locale(:"gd-GB") { expect(Petition.new.locale).to eq("gd-GB") }
    end
  end

  describe "#copy_content!" do
    let(:petition) do
      FactoryBot.create(:petition, :english,
        action_en: "Do stuff",
        background_en: "Because of reasons",
        additional_details_en: "Learn more at https://www.example.com",
        previous_action_en: "I've campaigned about it for years"
      )
    end

    it "copies over the action" do
      expect {
        petition.copy_content!
      }.to change {
        petition.reload.action_gd
      }.from(nil).to("Do stuff")
    end

    it "copies over the background" do
      expect {
        petition.copy_content!
      }.to change {
        petition.reload.background_gd
      }.from(nil).to("Because of reasons")
    end

    it "copies over the additional details" do
      expect {
        petition.copy_content!
      }.to change {
        petition.reload.additional_details_gd
      }.from(nil).to("Learn more at https://www.example.com")
    end

    it "copies over the previous action" do
      expect {
        petition.copy_content!
      }.to change {
        petition.reload.previous_action_gd
      }.from(nil).to("I've campaigned about it for years")
    end
  end

  describe "#reset_content!" do
    let(:petition) do
      FactoryBot.create(:petition, :english, :translated,
        action_en: "Do stuff",
        background_en: "Because of reasons",
        additional_details_en: "Learn more at https://www.example.com",
        previous_action_en: "I've campaigned about it for years"
      )
    end

    it "resets the action" do
      expect {
        petition.reset_content!
      }.to change {
        petition.reload.action_gd
      }.from("Do stuff").to(nil)
    end

    it "resets the background" do
      expect {
        petition.reset_content!
      }.to change {
        petition.reload.background_gd
      }.from("Because of reasons").to(nil)
    end

    it "resets the additional details" do
      expect {
        petition.reset_content!
      }.to change {
        petition.reload.additional_details_gd
      }.from("Learn more at https://www.example.com").to(nil)
    end

    it "resets the previous action" do
      expect {
        petition.reset_content!
      }.to change {
        petition.reload.previous_action_gd
      }.from("I've campaigned about it for years").to(nil)
    end
  end

  describe "#status" do
    mapping = [
      ['closed', 'closed'],
      ['completed', 'closed'],
      ['open', 'under_consideration'],
      ['hidden', 'rejected'],
      ['pending', 'pending']
    ]

    mapping.each do |state, status|
      context "when the petition is #{state}" do
        it "returns '#{status}'" do
          expect(FactoryBot.build("#{state}_petition").status).to eq status
        end
      end
    end
  end

  describe "#signature_count" do
    context "when the petition is collecting signatures" do
      let(:petition) { FactoryBot.create(:validated_petition, collect_signatures: true) }

      it "returns the correct signature count" do
        expect(petition.signature_count).to eq(1)
      end
    end

    context "when the petition is not collecting signatures" do
      let(:petition) { FactoryBot.create(:validated_petition, collect_signatures: false) }

      it "returns a signature count of 0" do
        expect(petition.signature_count).to eq(0)
      end
    end
  end
end
