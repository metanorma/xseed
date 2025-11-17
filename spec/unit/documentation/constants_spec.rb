# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/xseed/documentation/constants"

RSpec.describe Xseed::Documentation::Constants do
  describe "XSD namespace constant" do
    it "defines XSD_NS" do
      expect(described_class::XSD_NS).to eq("http://www.w3.org/2001/XMLSchema")
    end
  end

  describe "XML namespace constant" do
    it "defines XML_NS" do
      expect(described_class::XML_NS).to eq("http://www.w3.org/XML/1998/namespace")
    end
  end

  describe "indentation constants" do
    it "defines ELEM_INDENT" do
      expect(described_class::ELEM_INDENT).to eq(3)
    end

    it "defines ATTR_INDENT" do
      expect(described_class::ATTR_INDENT).to eq(2)
    end
  end

  describe "anchor prefix constants" do
    it "defines TYPE_PREFIX" do
      expect(described_class::TYPE_PREFIX).to eq("type_")
    end

    it "defines ELEM_PREFIX" do
      expect(described_class::ELEM_PREFIX).to eq("element_")
    end

    it "defines ATTR_PREFIX" do
      expect(described_class::ATTR_PREFIX).to eq("attribute_")
    end

    it "defines GROUP_PREFIX" do
      expect(described_class::GROUP_PREFIX).to eq("group_")
    end

    it "defines ATTR_GROUP_PREFIX" do
      expect(described_class::ATTR_GROUP_PREFIX).to eq("attributeGroup_")
    end

    it "defines KEY_PREFIX" do
      expect(described_class::KEY_PREFIX).to eq("key_")
    end

    it "defines NOTATION_PREFIX" do
      expect(described_class::NOTATION_PREFIX).to eq("notation_")
    end

    it "defines NS_PREFIX" do
      expect(described_class::NS_PREFIX).to eq("ns_")
    end

    it "defines TERM_PREFIX" do
      expect(described_class::TERM_PREFIX).to eq("term_")
    end
  end

  describe "default title constant" do
    it "defines DEFAULT_TITLE" do
      expect(described_class::DEFAULT_TITLE).to eq("XML Schema Documentation")
    end
  end

  describe "help text constants" do
    it "defines HELP_HIERARCHY" do
      expect(described_class::HELP_HIERARCHY).to include("type hierarchy")
    end

    it "defines HELP_PROPERTIES" do
      expect(described_class::HELP_PROPERTIES).to include("properties")
    end

    it "defines HELP_DOCUMENTATION" do
      expect(described_class::HELP_DOCUMENTATION).to include("documentation")
    end

    it "defines HELP_INSTANCE" do
      expect(described_class::HELP_INSTANCE).to include("XML Instance")
      expect(described_class::HELP_INSTANCE).to include("square brackets")
    end

    it "defines HELP_REPRESENTATION" do
      expect(described_class::HELP_REPRESENTATION).to include("Schema Component Representation")
    end
  end

  describe "navigation width constant" do
    it "defines NAV_WIDTH" do
      expect(described_class::NAV_WIDTH).to eq("270px")
    end
  end
end
