# frozen_string_literal: true

require "spec_helper"
require "xseed/documentation/utils/references"

RSpec.describe Xseed::Documentation::Utils::References do
  let(:test_class) { Class.new { include Xseed::Documentation::Utils::References } }
  let(:instance) { test_class.new }

  describe "#get_ref_name" do
    context "with qualified reference" do
      it "extracts local name from prefixed reference" do
        expect(instance.get_ref_name("xs:string")).to eq("string")
      end

      it "extracts local name from custom prefix" do
        expect(instance.get_ref_name("tns:MyType")).to eq("MyType")
      end

      it "handles multiple colons by taking after first colon" do
        expect(instance.get_ref_name("ns:name:with:colons")).to eq("name:with:colons")
      end
    end

    context "with unqualified reference" do
      it "returns the reference as-is" do
        expect(instance.get_ref_name("SimpleType")).to eq("SimpleType")
      end

      it "returns empty string for empty reference" do
        expect(instance.get_ref_name("")).to eq("")
      end
    end

    context "with nil reference" do
      it "returns empty string" do
        expect(instance.get_ref_name(nil)).to eq("")
      end
    end
  end

  describe "#get_ref_prefix" do
    context "with qualified reference" do
      it "extracts namespace prefix" do
        expect(instance.get_ref_prefix("xs:string")).to eq("xs")
      end

      it "extracts custom prefix" do
        expect(instance.get_ref_prefix("tns:MyType")).to eq("tns")
      end

      it "handles multiple colons by taking before first colon" do
        expect(instance.get_ref_prefix("ns:name:with:colons")).to eq("ns")
      end
    end

    context "with unqualified reference" do
      it "returns empty string" do
        expect(instance.get_ref_prefix("SimpleType")).to eq("")
      end

      it "returns empty string for empty reference" do
        expect(instance.get_ref_prefix("")).to eq("")
      end
    end

    context "with nil reference" do
      it "returns empty string" do
        expect(instance.get_ref_prefix(nil)).to eq("")
      end
    end
  end

  describe "#get_ref_namespace" do
    let(:schema) do
      double(
        "Schema",
        namespaces: {
          "xs" => "http://www.w3.org/2001/XMLSchema",
          "tns" => "http://example.com/target",
          "ext" => "http://example.com/extension"
        }
      )
    end

    context "with qualified reference" do
      it "resolves namespace from prefix" do
        result = instance.get_ref_namespace("xs:string", schema)
        expect(result).to eq("http://www.w3.org/2001/XMLSchema")
      end

      it "resolves custom namespace" do
        result = instance.get_ref_namespace("tns:MyType", schema)
        expect(result).to eq("http://example.com/target")
      end

      it "resolves extension namespace" do
        result = instance.get_ref_namespace("ext:CustomType", schema)
        expect(result).to eq("http://example.com/extension")
      end
    end

    context "with unqualified reference" do
      it "returns nil" do
        result = instance.get_ref_namespace("SimpleType", schema)
        expect(result).to be_nil
      end
    end

    context "with unknown prefix" do
      it "returns nil" do
        result = instance.get_ref_namespace("unknown:Type", schema)
        expect(result).to be_nil
      end
    end

    context "with nil reference" do
      it "returns nil" do
        result = instance.get_ref_namespace(nil, schema)
        expect(result).to be_nil
      end
    end

    context "with nil schema" do
      it "returns nil" do
        result = instance.get_ref_namespace("xs:string", nil)
        expect(result).to be_nil
      end
    end
  end

  describe "#get_this_prefix" do
    context "with target namespace" do
      let(:schema) do
        double(
          "Schema",
          target_namespace: "http://example.com/target",
          namespaces: {
            "tns" => "http://example.com/target",
            "xs" => "http://www.w3.org/2001/XMLSchema"
          }
        )
      end

      it "returns prefix for target namespace" do
        expect(instance.get_this_prefix(schema)).to eq("tns")
      end
    end

    context "without target namespace" do
      let(:schema) do
        double(
          "Schema",
          target_namespace: nil,
          namespaces: {}
        )
      end

      it "returns empty string" do
        expect(instance.get_this_prefix(schema)).to eq("")
      end
    end

    context "with nil schema" do
      it "returns empty string" do
        expect(instance.get_this_prefix(nil)).to eq("")
      end
    end
  end

  describe "#get_xsd_prefix" do
    context "with XSD namespace declared" do
      let(:schema) do
        double(
          "Schema",
          namespaces: {
            "xs" => "http://www.w3.org/2001/XMLSchema",
            "tns" => "http://example.com/target"
          }
        )
      end

      it "returns the XSD namespace prefix" do
        expect(instance.get_xsd_prefix(schema)).to eq("xs")
      end
    end

    context "with xsd prefix" do
      let(:schema) do
        double(
          "Schema",
          namespaces: {
            "xsd" => "http://www.w3.org/2001/XMLSchema"
          }
        )
      end

      it "returns xsd as prefix" do
        expect(instance.get_xsd_prefix(schema)).to eq("xsd")
      end
    end

    context "without XSD namespace" do
      let(:schema) do
        double(
          "Schema",
          namespaces: {
            "tns" => "http://example.com/target"
          }
        )
      end

      it "returns empty string" do
        expect(instance.get_xsd_prefix(schema)).to eq("")
      end
    end

    context "with nil schema" do
      it "returns empty string" do
        expect(instance.get_xsd_prefix(nil)).to eq("")
      end
    end
  end

  describe "#resolve_type_ref" do
    let(:schema) do
      double(
        "Schema",
        target_namespace: "http://example.com/target",
        namespaces: {
          "xs" => "http://www.w3.org/2001/XMLSchema",
          "tns" => "http://example.com/target",
          "ext" => "http://example.com/extension"
        }
      )
    end

    context "with qualified type reference" do
      it "resolves to namespace and local name" do
        result = instance.resolve_type_ref("xs:string", schema)
        expect(result).to eq({
                               namespace: "http://www.w3.org/2001/XMLSchema",
                               prefix: "xs",
                               local_name: "string"
                             })
      end

      it "resolves custom type reference" do
        result = instance.resolve_type_ref("tns:MyType", schema)
        expect(result).to eq({
                               namespace: "http://example.com/target",
                               prefix: "tns",
                               local_name: "MyType"
                             })
      end
    end

    context "with unqualified type reference" do
      it "returns local name without namespace" do
        result = instance.resolve_type_ref("SimpleType", schema)
        expect(result).to eq({
                               namespace: nil,
                               prefix: "",
                               local_name: "SimpleType"
                             })
      end
    end

    context "with nil reference" do
      it "returns empty values" do
        result = instance.resolve_type_ref(nil, schema)
        expect(result).to eq({
                               namespace: nil,
                               prefix: "",
                               local_name: ""
                             })
      end
    end
  end
end
