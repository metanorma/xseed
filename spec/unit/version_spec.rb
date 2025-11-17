# frozen_string_literal: true

RSpec.describe "Xseed::VERSION" do
  it "has a version number" do
    expect(Xseed::VERSION).not_to be_nil
  end

  it "is a string" do
    expect(Xseed::VERSION).to be_a(String)
  end

  it "follows semantic versioning format" do
    expect(Xseed::VERSION).to match(/^\d+\.\d+\.\d+/)
  end
end
