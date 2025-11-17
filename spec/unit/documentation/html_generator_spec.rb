# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/xseed/documentation/html_generator"

RSpec.describe Xseed::Documentation::HtmlGenerator do
  let(:xsd_file) { "spec/fixtures/simple/element_only.xsd" }
  let(:config) { Xseed::Documentation::Config.new }

  describe "#initialize" do
    it "creates generator with XSD file path" do
      generator = described_class.new(xsd_file)
      expect(generator).to be_a(described_class)
    end

    it "creates generator with XSD file and config" do
      generator = described_class.new(xsd_file, config)
      expect(generator).to be_a(described_class)
    end

    it "uses default config if not provided" do
      generator = described_class.new(xsd_file)
      expect(generator.config).to be_a(Xseed::Documentation::Config)
    end

    it "uses provided config" do
      custom_config = Xseed::Documentation::Config.new
      custom_config.title = "Custom Title"
      generator = described_class.new(xsd_file, custom_config)
      expect(generator.config.title).to eq("Custom Title")
    end
  end

  describe "#generate" do
    it "returns HTML string" do
      generator = described_class.new(xsd_file)
      html = generator.generate

      expect(html).to be_a(String)
      expect(html).to include("<html")
      expect(html).to include("</html>")
    end

    it "includes schema documentation content" do
      generator = described_class.new(xsd_file)
      html = generator.generate

      expect(html).to include("Schema Document Properties")
      expect(html).to include("Elements")
    end
  end

  describe "#generate_file" do
    let(:output_file) { "tmp/test_output.html" }

    before do
      FileUtils.mkdir_p("tmp")
    end

    after do
      FileUtils.rm_f(output_file)
    end

    it "writes HTML to file" do
      generator = described_class.new(xsd_file)
      generator.generate_file(output_file)

      expect(File).to exist(output_file)
      content = File.read(output_file)
      expect(content).to include("<html")
    end

    it "overwrites existing file" do
      File.write(output_file, "old content")
      generator = described_class.new(xsd_file)
      generator.generate_file(output_file)

      content = File.read(output_file)
      expect(content).not_to include("old content")
      expect(content).to include("<html")
    end
  end
end
