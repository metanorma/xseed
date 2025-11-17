# frozen_string_literal: true

require "spec_helper"
require "xseed/documentation/generators/instance_sample_generator"
require "xseed/parser/xsd_parser"
require "xseed/documentation/config"

RSpec.describe Xseed::Documentation::Generators::InstanceSampleGenerator do
  let(:config) { Xseed::Documentation::Config.new }
  let(:fixture_path) { File.expand_path("../../../fixtures", __dir__) }

  describe "#initialize" do
    it "requires a component parameter" do
      parser = Xseed::Parser::XsdParser.new(
        File.join(fixture_path, "simple/element_only.xsd")
      )
      expect do
        described_class.new(nil, parser, config)
      end.to raise_error(ArgumentError, "Component cannot be nil")
    end

    it "requires a parser parameter" do
      parser = Xseed::Parser::XsdParser.new(
        File.join(fixture_path, "simple/element_only.xsd")
      )
      element = parser.elements.first
      expect do
        described_class.new(element, nil, config)
      end.to raise_error(ArgumentError, "Parser cannot be nil")
    end

    it "accepts a config parameter" do
      parser = Xseed::Parser::XsdParser.new(
        File.join(fixture_path, "simple/element_only.xsd")
      )
      element = parser.elements.first
      generator = described_class.new(element, parser, config)
      expect(generator).to be_a(described_class)
    end
  end

  describe "#generate" do
    context "with simple element" do
      let(:parser) do
        Xseed::Parser::XsdParser.new(
          File.join(fixture_path, "simple/element_only.xsd")
        )
      end
      let(:element) { parser.elements.first }
      let(:generator) { described_class.new(element, parser, config) }

      it "returns HTML with instance sample wrapper" do
        result = generator.generate
        expect(result).to include('instance-sample')
        expect(result).to include('xml-code')
      end

      it "includes pre and code tags for syntax highlighting" do
        result = generator.generate
        expect(result).to include("<pre")
        expect(result).to include("<code")
        expect(result).to include("</code>")
        expect(result).to include("</pre>")
      end

      it "generates valid XML structure" do
        result = generator.generate
        doc = Nokogiri::HTML(result)
        xml_sample = doc.css("code").text
        expect(xml_sample).to include("<")
        expect(xml_sample).to include(">")
      end

      it "includes element name in sample" do
        result = generator.generate
        doc = Nokogiri::HTML(result)
        xml_sample = doc.css("code").text
        expect(xml_sample).to include(element["name"])
      end
    end

    context "with complex type element" do
      let(:xsd_content) do
        <<~XSD
          <?xml version="1.0" encoding="UTF-8"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:element name="person">
              <xs:complexType>
                <xs:sequence>
                  <xs:element name="name" type="xs:string"/>
                  <xs:element name="age" type="xs:integer"/>
                </xs:sequence>
              </xs:complexType>
            </xs:element>
          </xs:schema>
        XSD
      end

      it "generates nested element structure" do
        File.write("/tmp/test_complex_elem.xsd", xsd_content)
        parser = Xseed::Parser::XsdParser.new("/tmp/test_complex_elem.xsd")
        element = parser.elements.first
        generator = described_class.new(element, parser, config)
        result = generator.generate
        doc = Nokogiri::HTML(result)
        xml_sample = doc.css("code").text
        expect(xml_sample).to include("<person>")
        expect(xml_sample).to include("</person>")
        expect(xml_sample).to include("<name>")
        expect(xml_sample).to include("<age>")
        File.delete("/tmp/test_complex_elem.xsd")
      end
    end

    context "with element having attributes" do
      let(:xsd_content) do
        <<~XSD
          <?xml version="1.0" encoding="UTF-8"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:element name="book">
              <xs:complexType>
                <xs:simpleContent>
                  <xs:extension base="xs:string">
                    <xs:attribute name="isbn" type="xs:string" use="required"/>
                  </xs:extension>
                </xs:simpleContent>
              </xs:complexType>
            </xs:element>
          </xs:schema>
        XSD
      end

      it "includes attributes in sample" do
        File.write("/tmp/test_attrs.xsd", xsd_content)
        parser = Xseed::Parser::XsdParser.new("/tmp/test_attrs.xsd")
        element = parser.elements.first
        generator = described_class.new(element, parser, config)
        result = generator.generate
        doc = Nokogiri::HTML(result)
        xml_sample = doc.css("code").text
        expect(xml_sample).to include("isbn=")
        File.delete("/tmp/test_attrs.xsd")
      end
    end

    context "with complex type definition" do
      let(:xsd_content) do
        <<~XSD
          <?xml version="1.0" encoding="UTF-8"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:complexType name="AddressType">
              <xs:sequence>
                <xs:element name="street" type="xs:string"/>
                <xs:element name="city" type="xs:string"/>
              </xs:sequence>
            </xs:complexType>
          </xs:schema>
        XSD
      end

      it "generates sample for complex type" do
        File.write("/tmp/test_ctype.xsd", xsd_content)
        parser = Xseed::Parser::XsdParser.new("/tmp/test_ctype.xsd")
        complex_type = parser.complex_types.first
        generator = described_class.new(complex_type, parser, config)
        result = generator.generate
        doc = Nokogiri::HTML(result)
        xml_sample = doc.css("code").text
        expect(xml_sample).to include("<street>")
        expect(xml_sample).to include("<city>")
        File.delete("/tmp/test_ctype.xsd")
      end
    end

    context "with simple type definition" do
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

      it "generates sample showing constraints" do
        File.write("/tmp/test_stype.xsd", xsd_content)
        parser = Xseed::Parser::XsdParser.new("/tmp/test_stype.xsd")
        simple_type = parser.simple_types.first
        generator = described_class.new(simple_type, parser, config)
        result = generator.generate
        doc = Nokogiri::HTML(result)
        xml_sample = doc.css("code").text
        # Should show enumeration values
        expect(xml_sample).to match(/red|green|blue/)
        File.delete("/tmp/test_stype.xsd")
      end
    end
  end

  describe "XML structure features" do
    context "with choice model group" do
      let(:xsd_content) do
        <<~XSD
          <?xml version="1.0" encoding="UTF-8"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:element name="contact">
              <xs:complexType>
                <xs:choice>
                  <xs:element name="email" type="xs:string"/>
                  <xs:element name="phone" type="xs:string"/>
                </xs:choice>
              </xs:complexType>
            </xs:element>
          </xs:schema>
        XSD
      end

      it "shows choice indicator in sample" do
        File.write("/tmp/test_choice.xsd", xsd_content)
        parser = Xseed::Parser::XsdParser.new("/tmp/test_choice.xsd")
        element = parser.elements.first
        generator = described_class.new(element, parser, config)
        result = generator.generate
        doc = Nokogiri::HTML(result)
        xml_sample = doc.css("code").text
        # Should show choice elements
        expect(xml_sample).to include("email").or include("phone")
        File.delete("/tmp/test_choice.xsd")
      end
    end

    context "with sequence model group" do
      let(:xsd_content) do
        <<~XSD
          <?xml version="1.0" encoding="UTF-8"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:element name="person">
              <xs:complexType>
                <xs:sequence>
                  <xs:element name="firstName" type="xs:string"/>
                  <xs:element name="lastName" type="xs:string"/>
                </xs:sequence>
              </xs:complexType>
            </xs:element>
          </xs:schema>
        XSD
      end

      it "shows elements in sequence order" do
        File.write("/tmp/test_seq.xsd", xsd_content)
        parser = Xseed::Parser::XsdParser.new("/tmp/test_seq.xsd")
        element = parser.elements.first
        generator = described_class.new(element, parser, config)
        result = generator.generate
        doc = Nokogiri::HTML(result)
        xml_sample = doc.css("code").text
        expect(xml_sample).to include("firstName")
        expect(xml_sample).to include("lastName")
        File.delete("/tmp/test_seq.xsd")
      end
    end

    context "with occurrence constraints" do
      let(:xsd_content) do
        <<~XSD
          <?xml version="1.0" encoding="UTF-8"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:element name="items">
              <xs:complexType>
                <xs:sequence>
                  <xs:element name="item" type="xs:string" minOccurs="0" maxOccurs="unbounded"/>
                </xs:sequence>
              </xs:complexType>
            </xs:element>
          </xs:schema>
        XSD
      end

      it "indicates occurrence information" do
        File.write("/tmp/test_occurs.xsd", xsd_content)
        parser = Xseed::Parser::XsdParser.new("/tmp/test_occurs.xsd")
        element = parser.elements.first
        generator = described_class.new(element, parser, config)
        result = generator.generate
        doc = Nokogiri::HTML(result)
        xml_sample = doc.css("code").text
        # Should show occurrence indicators
        expect(xml_sample).to include("item")
        File.delete("/tmp/test_occurs.xsd")
      end
    end
  end

  describe "indentation and formatting" do
    let(:xsd_content) do
      <<~XSD
        <?xml version="1.0" encoding="UTF-8"?>
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
          <xs:element name="root">
            <xs:complexType>
              <xs:sequence>
                <xs:element name="child" type="xs:string"/>
              </xs:sequence>
            </xs:complexType>
          </xs:element>
        </xs:schema>
      XSD
    end

    it "produces properly indented XML" do
      File.write("/tmp/test_indent.xsd", xsd_content)
      parser = Xseed::Parser::XsdParser.new("/tmp/test_indent.xsd")
      element = parser.elements.first
      generator = described_class.new(element, parser, config)
      result = generator.generate
      doc = Nokogiri::HTML(result)
      xml_sample = doc.css("code").text
      # Should have newlines and indentation
      expect(xml_sample).to include("\n")
      File.delete("/tmp/test_indent.xsd")
    end
  end

  describe "namespace handling" do
    let(:xsd_content) do
      <<~XSD
        <?xml version="1.0" encoding="UTF-8"?>
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"
                   targetNamespace="http://example.com/test"
                   xmlns:tns="http://example.com/test">
          <xs:element name="testElement" type="xs:string"/>
        </xs:schema>
      XSD
    end

    it "includes namespace declaration for target namespace" do
      File.write("/tmp/test_ns.xsd", xsd_content)
      parser = Xseed::Parser::XsdParser.new("/tmp/test_ns.xsd")
      element = parser.elements.first
      generator = described_class.new(element, parser, config)
      result = generator.generate
      doc = Nokogiri::HTML(result)
      xml_sample = doc.css("code").text
      expect(xml_sample).to include("xmlns=")
      File.delete("/tmp/test_ns.xsd")
    end
  end

  describe "type reference handling" do
    let(:xsd_content) do
      <<~XSD
        <?xml version="1.0" encoding="UTF-8"?>
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
          <xs:complexType name="PersonType">
            <xs:sequence>
              <xs:element name="name" type="xs:string"/>
            </xs:sequence>
          </xs:complexType>
          <xs:element name="person" type="PersonType"/>
        </xs:schema>
      XSD
    end

    it "resolves type references" do
      File.write("/tmp/test_typeref.xsd", xsd_content)
      parser = Xseed::Parser::XsdParser.new("/tmp/test_typeref.xsd")
      element = parser.elements.first
      generator = described_class.new(element, parser, config)
      result = generator.generate
      doc = Nokogiri::HTML(result)
      xml_sample = doc.css("code").text
      expect(xml_sample).to include("<person>")
      expect(xml_sample).to include("<name>")
      File.delete("/tmp/test_typeref.xsd")
    end
  end

  describe "edge cases" do
    it "handles empty complex type" do
      xsd_content = <<~XSD
        <?xml version="1.0" encoding="UTF-8"?>
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
          <xs:element name="empty">
            <xs:complexType/>
          </xs:element>
        </xs:schema>
      XSD
      File.write("/tmp/test_empty.xsd", xsd_content)
      parser = Xseed::Parser::XsdParser.new("/tmp/test_empty.xsd")
      element = parser.elements.first
      generator = described_class.new(element, parser, config)
      result = generator.generate
      expect(result).to include("instance-sample")
      File.delete("/tmp/test_empty.xsd")
    end

    it "handles mixed content" do
      xsd_content = <<~XSD
        <?xml version="1.0" encoding="UTF-8"?>
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
          <xs:element name="para">
            <xs:complexType mixed="true">
              <xs:sequence>
                <xs:element name="bold" type="xs:string"/>
              </xs:sequence>
            </xs:complexType>
          </xs:element>
        </xs:schema>
      XSD
      File.write("/tmp/test_mixed.xsd", xsd_content)
      parser = Xseed::Parser::XsdParser.new("/tmp/test_mixed.xsd")
      element = parser.elements.first
      generator = described_class.new(element, parser, config)
      result = generator.generate
      expect(result).to include("instance-sample")
      File.delete("/tmp/test_mixed.xsd")
    end

    it "prevents infinite recursion with circular types" do
      xsd_content = <<~XSD
        <?xml version="1.0" encoding="UTF-8"?>
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
          <xs:complexType name="NodeType">
            <xs:sequence>
              <xs:element name="value" type="xs:string"/>
              <xs:element name="next" type="NodeType" minOccurs="0"/>
            </xs:sequence>
          </xs:complexType>
          <xs:element name="node" type="NodeType"/>
        </xs:schema>
      XSD
      File.write("/tmp/test_circular.xsd", xsd_content)
      parser = Xseed::Parser::XsdParser.new("/tmp/test_circular.xsd")
      element = parser.elements.first
      generator = described_class.new(element, parser, config)
      expect { generator.generate }.not_to raise_error
      File.delete("/tmp/test_circular.xsd")
    end
  end

  describe "HTML output structure" do
    let(:parser) do
      Xseed::Parser::XsdParser.new(
        File.join(fixture_path, "simple/element_only.xsd")
      )
    end
    let(:element) { parser.elements.first }
    let(:generator) { described_class.new(element, parser, config) }

    it "generates valid HTML" do
      result = generator.generate
      doc = Nokogiri::HTML(result)
      expect(doc.errors).to be_empty
    end

    it "includes xml-code class for styling" do
      result = generator.generate
      expect(result).to include('xml-code')
    end

    it "includes language-xml class for syntax highlighting" do
      result = generator.generate
      expect(result).to include('class="language-xml"')
    end
  end
end
