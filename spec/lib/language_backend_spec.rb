require 'rails_helper'

RSpec.describe LanguageBackend do
  around do |example|
    backend = I18n.backend
    I18n.backend = described_class.new
    I18n.reload!

    example.run
  ensure
    I18n.backend = backend
    I18n.reload!
  end

  describe "#available_locales" do
    it "calls Language.available_locales" do
      expect(Language).to receive(:available_locales).and_return(%i[en-GB gd-GB])
      expect(I18n.available_locales).to eq(%i[en-GB gd-GB])
    end
  end

  describe "#lookup" do
    it "calls Language.lookup" do
      expect(Language).to receive(:available_locales).and_return(%i[en-GB gd-GB])
      expect(Language).to receive(:lookup).with(:"en-GB", :"ui.site_title", nil, {}).and_return("Gaelic Petitions")
      expect(I18n.translate(:"ui.site_title")).to eq("Gaelic Petitions")
    end
  end
end
