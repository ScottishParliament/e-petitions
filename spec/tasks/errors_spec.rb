require 'rails_helper'

RSpec.describe "errors:precompile", type: :task do
  let(:public_path) { Pathname.new(Dir.mktmpdir) }
  let(:public_files) { public_path.entries.map(&:to_s) }

  before do
    allow(Rails).to receive(:public_path).and_return(public_path)

    subject.invoke
  end

  after do
    FileUtils.remove_entry(public_path)
  end

  it "renders the error pages" do
    expect(public_files).to include('400.html')
    expect(public_files).to include('403.html')
    expect(public_files).to include('404.html')
    expect(public_files).to include('406.html')
    expect(public_files).to include('410.html')
    expect(public_files).to include('422.html')
    expect(public_files).to include('500.html')
    expect(public_files).to include('503.html')
    expect(public_files).to include('FuturaBT-Book.ttf')
  end
end

RSpec.describe "errors:clobber", type: :task do
  let(:public_path) { Pathname.new(Dir.mktmpdir) }
  let(:public_files) { public_path.entries.map(&:to_s) }
  let(:generated_files) { %w[400 403 404 406 410 422 500 503].map { |s| "#{s}.html" } + %w[FuturaBT-Book.ttf] }

  before do
    allow(Rails).to receive(:public_path).and_return(public_path)

    generated_files.each { |file| FileUtils.touch(public_path.join(file)) }
    FileUtils.touch(public_path.join("robots.txt"))

    subject.invoke
  end

  after do
    FileUtils.remove_entry(public_path)
  end

  it "removes the generated error pages and font" do
    expect(public_files).not_to include(*generated_files)
  end

  it "leaves other public files alone" do
    expect(public_files).to include("robots.txt")
  end
end
