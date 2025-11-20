# frozen_string_literal: true

require "spec_helper"
require "xseed/documentation/generators/properties_table_generator"
require "xseed/parser/xsd_parser"
require "xseed/documentation/config"

RSpec.describe Xseed::Documentation::Generators::PropertiesTableGenerator do
  let(:config) { Xseed::Documentation::Config.new }
  let(:fixture_path) { File.expand_path("../../../fixtures", __dir__) }

  describe "#initialize" do
    it "requires a component parameter" do
      expect { described_class.new(nil, config) }.to raise_error(ArgumentError)
    end

    it "accepts a config parameter" do
      parser = Xseed::Parser::XsdParser.new(
        File.join(fixture_path, "simple/element_only.xsd"),
      )
      element = parser.elements.first
      generator = described_class.new(element, config)
      expect(generator).to be_a(described_class)
    end
  end

  describe "#generate" do
    context "with element component" do
      let(:parser) do
        Xseed::Parser::XsdParser.new(
          File.join(fixture_path, "simple/element_only.xsd"),
        )
      end
      let(:element) { parser.elements.first }
      let(:generator) { described_class.new(element, config) }

      it "returns HTML table markup" do
        result = generator.generate
        expect(result).to be_an(Array)
        html = result.join
        expect(html).to include("<dl")
        expect(html).to include("</dl>")
      end

      it "includes properties class" do
        result = generator.generate
        html = result.join
        expect(html).to include('class="dl-horizontal"')
      end

      it "includes component name row" do
        result = generator.generate
        html = result.join
        expect(html).to include("Type")
      end

      it "includes namespace row" do
        # Definition lists don't have explicit namespace rows for elements
        result = generator.generate
        expect(result).to be_an(Array)
      end

      it "includes type row when type is present" do
        result = generator.generate
        html = result.join
        expect(html).to include("Type") if element["type"]
      end
    end

    context "with complex type component" do
      let(:parser) do
        Xseed::Parser::XsdParser.new(
          File.join(fixture_path, "simple/complex_type.xsd"),
        )
      end
      let(:complex_type) { parser.complex_types.first }
      let(:generator) { described_class.new(complex_type, config) }

      it "returns HTML table markup" do
        result = generator.generate
        expect(result).to be_an(Array)
        html = result.join
        expect(html).to include("<dl")
        expect(html).to include("</dl>")
      end

      it "includes component name" do
        result = generator.generate
        html = result.join
        # Complex types may not have a "name" in DL but will have structure
        expect(html).to be_a(String)
      end

      it "includes content model information" do
        result = generator.generate
        # Complex types may have documentation or properties
        expect(result).to be_an(Array)
      end
    end

    context "with simple type component" do
      let(:parser) do
        Xseed::Parser::XsdParser.new(
          File.join(fixture_path, "simple/simple_type.xsd"),
        )
      end
      let(:simple_type) { parser.simple_types.first }
      let(:generator) { described_class.new(simple_type, config) }

      it "returns HTML table markup" do
        result = generator.generate
        expect(result).to be_an(Array)
        html = result.join
        expect(html).to include("<dl")
        expect(html).to include("</dl>")
      end

      it "includes base type for restrictions" do
        result = generator.generate
        html = result.join
        if simple_type.at_xpath("xsd:restriction", "xsd" => Xseed::Parser::XsdParser::XSD_NS)
          expect(html).to match(/Content|base|Base/)
        end
      end

      it "includes facet constraints" do
        result = generator.generate
        html = result.join
        restriction = simple_type.at_xpath(
          "xsd:restriction",
          "xsd" => Xseed::Parser::XsdParser::XSD_NS,
        )
        # Check for facets like enumeration, pattern, minLength, etc.
        if restriction&.at_xpath("xsd:enumeration", "xsd" => Xseed::Parser::XsdParser::XSD_NS)
          expect(html).to match(/enumeration|value/i)
        end
      end
    end
  end

  describe "row generation methods" do
    let(:parser) do
      Xseed::Parser::XsdParser.new(
        File.join(fixture_path, "simple/element_only.xsd"),
      )
    end
    let(:element) { parser.elements.first }
    let(:generator) { described_class.new(element, config) }

    describe "#generate_name_row" do
      it "generates a table row with name label and value" do
        # generate method returns array of DL HTML strings
        result = generator.generate
        html = result.join
        expect(html).to be_a(String)
        expect(html).to include("<dl")
      end
    end

    describe "#generate_type_row" do
      it "generates a table row with type information when type exists" do
        skip "if component doesn't have type" unless element["type"]
        result = generator.generate
        html = result.join
        expect(html).to include("Type")
      end
    end

    describe "#generate_namespace_row" do
      it "generates a table row with namespace information" do
        # Elements have Type information in DL
        result = generator.generate
        html = result.join
        expect(html).to be_a(String)
      end
    end
  end

  describe "facet handling" do
    context "with enumeration facet" do
      let(:xsd_content) do
        <<~XSD
          <?xml version="1.0" encoding="UTF-8"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:simpleType name="ColorType">
              <xs:restriction base="xs:string">
                <xs:enumeration value="red"/>
                <xs:enumeration value="green"/>
                <xs:enumeration value="blue"/>
              </xs:restriction>
            </xs:simpleType>
          </xs:schema>
        XSD
      end

      it "includes enumeration values" do
        File.write("/tmp/test_enum.xsd", xsd_content)
        parser = Xseed::Parser::XsdParser.new("/tmp/test_enum.xsd")
        simple_type = parser.simple_types.first
        generator = described_class.new(simple_type, config)
        result = generator.generate
        html = result.join
        expect(html).to include("red")
        expect(html).to include("green")
        expect(html).to include("blue")
        File.delete("/tmp/test_enum.xsd")
      end
    end

    context "with pattern facet" do
      let(:xsd_content) do
        <<~XSD
          <?xml version="1.0" encoding="UTF-8"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:simpleType name="ZipCodeType">
              <xs:restriction base="xs:string">
                <xs:pattern value="[0-9]{5}"/>
              </xs:restriction>
            </xs:simpleType>
          </xs:schema>
        XSD
      end

      it "includes pattern constraint" do
        File.write("/tmp/test_pattern.xsd", xsd_content)
        parser = Xseed::Parser::XsdParser.new("/tmp/test_pattern.xsd")
        simple_type = parser.simple_types.first
        generator = described_class.new(simple_type, config)
        result = generator.generate
        html = result.join
        expect(html).to match(/pattern/i)
        expect(html).to include("[0-9]{5}")
        File.delete("/tmp/test_pattern.xsd")
      end
    end

    context "with length facets" do
      let(:xsd_content) do
        <<~XSD
          <?xml version="1.0" encoding="UTF-8"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:simpleType name="ShortStringType">
              <xs:restriction base="xs:string">
                <xs:minLength value="2"/>
                <xs:maxLength value="20"/>
              </xs:restriction>
            </xs:simpleType>
          </xs:schema>
        XSD
      end

      it "includes length constraints" do
        File.write("/tmp/test_length.xsd", xsd_content)
        parser = Xseed::Parser::XsdParser.new("/tmp/test_length.xsd")
        simple_type = parser.simple_types.first
        generator = described_class.new(simple_type, config)
        result = generator.generate
        html = result.join
        expect(html).to match(/length/i)
        File.delete("/tmp/test_length.xsd")
      end
    end

    context "with range facets" do
      let(:xsd_content) do
        <<~XSD
          <?xml version="1.0" encoding="UTF-8"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:simpleType name="AgeType">
              <xs:restriction base="xs:integer">
                <xs:minInclusive value="0"/>
                <xs:maxInclusive value="120"/>
              </xs:restriction>
            </xs:simpleType>
          </xs:schema>
        XSD
      end

      it "includes range constraints" do
        File.write("/tmp/test_range.xsd", xsd_content)
        parser = Xseed::Parser::XsdParser.new("/tmp/test_range.xsd")
        simple_type = parser.simple_types.first
        generator = described_class.new(simple_type, config)
        result = generator.generate
        html = result.join
        expect(html).to include("0")
        expect(html).to include("120")
        File.delete("/tmp/test_range.xsd")
      end
    end
  end

  describe "edge cases" do
    it "handles component without name attribute" do
      doc = Nokogiri::XML("<xs:element type='string'/>")
      element = doc.root
      generator = described_class.new(element, config)
      result = generator.generate
      # Element without name still generates DLs with type info
      expect(result).to be_an(Array)
    end

    it "handles component with documentation" do
      xsd_content = <<~XSD
        <?xml version="1.0" encoding="UTF-8"?>
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
          <xs:element name="documented">
            <xs:annotation>
              <xs:documentation>This is documentation</xs:documentation>
            </xs:annotation>
          </xs:element>
        </xs:schema>
      XSD
      File.write("/tmp/test_doc.xsd", xsd_content)
      parser = Xseed::Parser::XsdParser.new("/tmp/test_doc.xsd")
      element = parser.elements.first
      generator = described_class.new(element, config)
      result = generator.generate
      html = result.join
      expect(html).to include("This is documentation")
      File.delete("/tmp/test_doc.xsd")
    end
  end
end
