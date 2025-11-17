# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/xseed/documentation/config"

RSpec.describe Xseed::Documentation::Config do
  describe "#initialize" do
    it "creates a config with default values" do
      config = described_class.new

      expect(config.title).to be_nil
      expect(config.sort_by_component).to be true
      expect(config.print_glossary).to be true
      expect(config.print_all_super_types).to be true
      expect(config.print_all_sub_types).to be true
      expect(config.print_ns_prefixes).to be true
      expect(config.search_included_schemas).to be false
      expect(config.search_imported_schemas).to be false
      expect(config.links_file).to be_nil
      expect(config.base_url).to be_nil
      expect(config.external_css_url).to be_nil
      expect(config.jquery_url).to eq("https://cdnjs.cloudflare.com/ajax/libs/jquery/2.2.4/jquery.min.js")
      expect(config.bootstrap_url).to eq("https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/3.4.1")
    end
  end

  describe "attribute accessors" do
    let(:config) { described_class.new }

    it "allows setting title" do
      config.title = "My Schema"
      expect(config.title).to eq("My Schema")
    end

    it "allows setting sort_by_component" do
      config.sort_by_component = false
      expect(config.sort_by_component).to be false
    end

    it "allows setting print_glossary" do
      config.print_glossary = false
      expect(config.print_glossary).to be false
    end

    it "allows setting print_all_super_types" do
      config.print_all_super_types = false
      expect(config.print_all_super_types).to be false
    end

    it "allows setting print_all_sub_types" do
      config.print_all_sub_types = false
      expect(config.print_all_sub_types).to be false
    end

    it "allows setting print_ns_prefixes" do
      config.print_ns_prefixes = false
      expect(config.print_ns_prefixes).to be false
    end

    it "allows setting search_included_schemas" do
      config.search_included_schemas = true
      expect(config.search_included_schemas).to be true
    end

    it "allows setting search_imported_schemas" do
      config.search_imported_schemas = true
      expect(config.search_imported_schemas).to be true
    end

    it "allows setting links_file" do
      config.links_file = "links.xml"
      expect(config.links_file).to eq("links.xml")
    end

    it "allows setting base_url" do
      config.base_url = "https://example.com"
      expect(config.base_url).to eq("https://example.com")
    end

    it "allows setting external_css_url" do
      config.external_css_url = "styles.css"
      expect(config.external_css_url).to eq("styles.css")
    end

    it "allows setting jquery_url" do
      config.jquery_url = "custom-jquery.js"
      expect(config.jquery_url).to eq("custom-jquery.js")
    end

    it "allows setting bootstrap_url" do
      config.bootstrap_url = "custom-bootstrap"
      expect(config.bootstrap_url).to eq("custom-bootstrap")
    end
  end

  describe "#to_h" do
    it "returns configuration as hash" do
      config = described_class.new
      config.title = "Test Schema"
      config.sort_by_component = false

      hash = config.to_h

      expect(hash).to be_a(Hash)
      expect(hash[:title]).to eq("Test Schema")
      expect(hash[:sort_by_component]).to be false
      expect(hash[:print_glossary]).to be true
    end
  end
end
