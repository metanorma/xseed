# frozen_string_literal: true

require "spec_helper"
require "xseed/documentation/utils/namespaces"

RSpec.describe Xseed::Documentation::Utils::Namespaces do
  let(:test_class) { Class.new { include Xseed::Documentation::Utils::Namespaces } }
  let(:instance) { test_class.new }

  describe "#format_namespace_prefix" do
    context "with valid prefix" do
      it "formats prefix with colon" do
        expect(instance.format_namespace_prefix("xs")).to eq("xs:")
      end

      it "formats custom prefix with colon" do
        expect(instance.format_namespace_prefix("tns")).to eq("tns:")
      end
    end

    context "with empty prefix" do
      it "returns empty string" do
        expect(instance.format_namespace_prefix("")).to eq("")
      end
    end

    context "with nil prefix" do
      it "returns empty string" do
        expect(instance.format_namespace_prefix(nil)).to eq("")
      end
    end

    context "with whitespace prefix" do
      it "returns empty string" do
        expect(instance.format_namespace_prefix("  ")).to eq("")
      end
    end
  end

  describe "#namespace_link" do
    let(:schema) do
      double(
        "Schema",
        namespaces: {
          "xs" => "http://www.w3.org/2001/XMLSchema",
          "tns" => "http://example.com/target",
        },
      )
    end

    context "with known namespace prefix" do
      it "generates HTML link to namespace declaration" do
        result = instance.namespace_link("xs", schema)
        expect(result).to include('href="#ns-xs"')
        expect(result).to include(">xs<")
        expect(result).to include("title=")
      end

      it "generates link for custom prefix" do
        result = instance.namespace_link("tns", schema)
        expect(result).to include('href="#ns-tns"')
        expect(result).to include(">tns<")
      end
    end

    context "with unknown namespace prefix" do
      it "generates link with warning" do
        result = instance.namespace_link("unknown", schema)
        expect(result).to include("unknown")
        expect(result).to include("Unknown namespace prefix")
      end
    end

    context "with empty prefix" do
      it "returns empty string" do
        expect(instance.namespace_link("", schema)).to eq("")
      end
    end

    context "with nil prefix" do
      it "returns empty string" do
        expect(instance.namespace_link(nil, schema)).to eq("")
      end
    end

    context "with external schema location" do
      it "generates link with schema location" do
        result = instance.namespace_link("xs", schema,
                                         schema_loc: "external.xsd")
        expect(result).to include("external.xsd#ns-xs")
      end
    end
  end

  describe "#format_namespace_with_prefix" do
    let(:schema) do
      double(
        "Schema",
        namespaces: {
          "xs" => "http://www.w3.org/2001/XMLSchema",
          "tns" => "http://example.com/target",
        },
      )
    end

    context "with valid prefix and link enabled" do
      it "returns linked prefix with colon" do
        result = instance.format_namespace_with_prefix("xs", schema)
        expect(result).to include('href="#ns-xs"')
        expect(result).to include(">xs<")
        expect(result).to include(":")
      end
    end

    context "with valid prefix and link disabled" do
      it "returns plain prefix with colon" do
        result = instance.format_namespace_with_prefix("xs", schema,
                                                       link: false)
        expect(result).to eq("xs:")
        expect(result).not_to include("href")
      end
    end

    context "with empty prefix" do
      it "returns empty string" do
        result = instance.format_namespace_with_prefix("", schema)
        expect(result).to eq("")
      end
    end
  end

  describe "#collect_namespaces" do
    let(:schema) do
      double(
        "Schema",
        namespaces: {
          "xs" => "http://www.w3.org/2001/XMLSchema",
          "tns" => "http://example.com/target",
          "ext" => "http://example.com/extension",
        },
        target_namespace: "http://example.com/target",
      )
    end

    it "returns all namespaces from schema" do
      result = instance.collect_namespaces(schema)
      expect(result).to be_a(Hash)
      expect(result.size).to eq(3)
      expect(result["xs"]).to eq("http://www.w3.org/2001/XMLSchema")
      expect(result["tns"]).to eq("http://example.com/target")
      expect(result["ext"]).to eq("http://example.com/extension")
    end

    context "with nil schema" do
      it "returns empty hash" do
        expect(instance.collect_namespaces(nil)).to eq({})
      end
    end

    context "with schema without namespaces" do
      let(:empty_schema) { double("Schema", namespaces: nil) }

      it "returns empty hash" do
        expect(instance.collect_namespaces(empty_schema)).to eq({})
      end
    end
  end

  describe "#namespace_anchor_id" do
    it "generates anchor ID for namespace prefix" do
      expect(instance.namespace_anchor_id("xs")).to eq("ns-xs")
    end

    it "generates anchor ID for custom prefix" do
      expect(instance.namespace_anchor_id("tns")).to eq("ns-tns")
    end

    context "with empty prefix" do
      it "returns base anchor" do
        expect(instance.namespace_anchor_id("")).to eq("ns-")
      end
    end

    context "with nil prefix" do
      it "returns base anchor" do
        expect(instance.namespace_anchor_id(nil)).to eq("ns-")
      end
    end
  end

  describe "#format_namespace_declaration" do
    it "formats xmlns declaration" do
      result = instance.format_namespace_declaration(
        "xs",
        "http://www.w3.org/2001/XMLSchema",
      )
      expect(result).to include("xmlns:xs")
      expect(result).to include("http://www.w3.org/2001/XMLSchema")
    end

    it "formats default namespace declaration" do
      result = instance.format_namespace_declaration(
        "",
        "http://example.com/default",
      )
      expect(result).to include("xmlns=")
      expect(result).to include("http://example.com/default")
      expect(result).not_to include("xmlns:")
    end

    context "with nil values" do
      it "handles nil prefix" do
        result = instance.format_namespace_declaration(
          nil,
          "http://example.com",
        )
        expect(result).to include("xmlns=")
      end

      it "handles nil namespace" do
        result = instance.format_namespace_declaration("xs", nil)
        expect(result).to include("xmlns:xs")
      end
    end
  end
end
