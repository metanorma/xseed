# frozen_string_literal: true

require "spec_helper"
require "xseed/documentation/generators/hierarchy_table_generator"
require "xseed/parser/xsd_parser"
require "xseed/documentation/config"

RSpec.describe Xseed::Documentation::Generators::HierarchyTableGenerator do
  let(:config) { Xseed::Documentation::Config.new }
  let(:fixture_path) { File.expand_path("../../../fixtures", __dir__) }

  describe "#initialize" do
    it "requires a component parameter" do
      parser = Xseed::Parser::XsdParser.new(
        File.join(fixture_path, "simple/element_only.xsd")
      )
      expect { described_class.new(nil, parser, config) }
        .to raise_error(ArgumentError)
    end

    it "requires a parser parameter" do
      parser = Xseed::Parser::XsdParser.new(
        File.join(fixture_path, "simple/element_only.xsd")
      )
      element = parser.elements.first
      expect { described_class.new(element, nil, config) }
        .to raise_error(ArgumentError)
    end

    it "accepts all required parameters" do
      parser = Xseed::Parser::XsdParser.new(
        File.join(fixture_path, "simple/element_only.xsd")
      )
      element = parser.elements.first
      generator = described_class.new(element, parser, config)
      expect(generator).to be_a(described_class)
    end
  end

  describe "#generate" do
    context "with element that has no hierarchy" do
      let(:parser) do
        Xseed::Parser::XsdParser.new(
          File.join(fixture_path, "simple/element_only.xsd")
        )
      end
      let(:element) { parser.elements.first }
      let(:generator) { described_class.new(element, parser, config) }

      it "returns nil when element has no hierarchy" do
        result = generator.generate
        expect(result).to be_nil
      end
    end

    context "with element that has substitution group" do
      let(:xsd_content) do
        <<~XSD
          <?xml version="1.0" encoding="UTF-8"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:element name="baseElement" type="xs:string"/>
            <xs:element name="substitutableElement"
                        type="xs:string"
                        substitutionGroup="baseElement"/>
          </xs:schema>
        XSD
      end

      it "generates hierarchy table with substitution information" do
        File.write("/tmp/test_subst.xsd", xsd_content)
        parser = Xseed::Parser::XsdParser.new("/tmp/test_subst.xsd")
        element = parser.elements.last
        generator = described_class.new(element, parser, config)
        result = generator.generate
        expect(result).to include("wherever")
        expect(result).to include("baseElement")
        File.delete("/tmp/test_subst.xsd")
      end
    end

    context "with complex type that has base type" do
      let(:xsd_content) do
        <<~XSD
          <?xml version="1.0" encoding="UTF-8"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:complexType name="BaseType">
              <xs:sequence>
                <xs:element name="baseField" type="xs:string"/>
              </xs:sequence>
            </xs:complexType>
            <xs:complexType name="DerivedType">
              <xs:complexContent>
                <xs:extension base="BaseType">
                  <xs:sequence>
                    <xs:element name="derivedField" type="xs:string"/>
                  </xs:sequence>
                </xs:extension>
              </xs:complexContent>
            </xs:complexType>
          </xs:schema>
        XSD
      end

      it "generates hierarchy table with supertype information" do
        File.write("/tmp/test_hierarchy.xsd", xsd_content)
        parser = Xseed::Parser::XsdParser.new("/tmp/test_hierarchy.xsd")
        derived_type = parser.complex_types.last
        generator = described_class.new(derived_type, parser, config)
        result = generator.generate
        expect(result).to include("Super-type")
        expect(result).to include("BaseType")
        File.delete("/tmp/test_hierarchy.xsd")
      end

      it "shows derivation method" do
        File.write("/tmp/test_hierarchy2.xsd", xsd_content)
        parser = Xseed::Parser::XsdParser.new("/tmp/test_hierarchy2.xsd")
        derived_type = parser.complex_types.last
        generator = described_class.new(derived_type, parser, config)
        result = generator.generate
        expect(result).to match(/extension|Extension/)
        File.delete("/tmp/test_hierarchy2.xsd")
      end
    end

    context "with complex type that has derived types" do
      let(:xsd_content) do
        <<~XSD
          <?xml version="1.0" encoding="UTF-8"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:complexType name="BaseType">
              <xs:sequence>
                <xs:element name="baseField" type="xs:string"/>
              </xs:sequence>
            </xs:complexType>
            <xs:complexType name="DerivedType1">
              <xs:complexContent>
                <xs:extension base="BaseType">
                  <xs:sequence>
                    <xs:element name="field1" type="xs:string"/>
                  </xs:sequence>
                </xs:extension>
              </xs:complexContent>
            </xs:complexType>
            <xs:complexType name="DerivedType2">
              <xs:complexContent>
                <xs:restriction base="BaseType">
                  <xs:sequence>
                    <xs:element name="baseField" type="xs:string" fixed="value"/>
                  </xs:sequence>
                </xs:restriction>
              </xs:complexContent>
            </xs:complexType>
          </xs:schema>
        XSD
      end

      it "generates hierarchy table with subtype information" do
        File.write("/tmp/test_subtypes.xsd", xsd_content)
        parser = Xseed::Parser::XsdParser.new("/tmp/test_subtypes.xsd")
        base_type = parser.complex_types.first
        generator = described_class.new(base_type, parser, config)
        result = generator.generate
        expect(result).to include("Sub-type")
        expect(result).to include("DerivedType1")
        expect(result).to include("DerivedType2")
        File.delete("/tmp/test_subtypes.xsd")
      end
    end

    context "with simple type that has base type" do
      let(:xsd_content) do
        <<~XSD
          <?xml version="1.0" encoding="UTF-8"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:simpleType name="BaseType">
              <xs:restriction base="xs:string">
                <xs:minLength value="1"/>
              </xs:restriction>
            </xs:simpleType>
            <xs:simpleType name="DerivedType">
              <xs:restriction base="BaseType">
                <xs:maxLength value="50"/>
              </xs:restriction>
            </xs:simpleType>
          </xs:schema>
        XSD
      end

      it "generates hierarchy table with supertype information" do
        File.write("/tmp/test_simple_hierarchy.xsd", xsd_content)
        parser = Xseed::Parser::XsdParser.new("/tmp/test_simple_hierarchy.xsd")
        derived_type = parser.simple_types.last
        generator = described_class.new(derived_type, parser, config)
        result = generator.generate
        expect(result).to include("Super-type")
        expect(result).to include("BaseType")
        File.delete("/tmp/test_simple_hierarchy.xsd")
      end
    end
  end

  describe "#has_hierarchy?" do
    context "with element" do
      it "returns true when element has substitutionGroup attribute" do
        xsd_content = <<~XSD
          <?xml version="1.0" encoding="UTF-8"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:element name="base" type="xs:string"/>
            <xs:element name="derived" type="xs:string" substitutionGroup="base"/>
          </xs:schema>
        XSD
        File.write("/tmp/test_has_subst.xsd", xsd_content)
        parser = Xseed::Parser::XsdParser.new("/tmp/test_has_subst.xsd")
        element = parser.elements.last
        generator = described_class.new(element, parser, config)
        expect(generator.send(:has_hierarchy?)).to be true
        File.delete("/tmp/test_has_subst.xsd")
      end

      it "returns false when element has no substitution group" do
        parser = Xseed::Parser::XsdParser.new(
          File.join(fixture_path, "simple/element_only.xsd")
        )
        element = parser.elements.first
        generator = described_class.new(element, parser, config)
        expect(generator.send(:has_hierarchy?)).to be false
      end
    end

    context "with complex type" do
      it "returns true when type has base type" do
        xsd_content = <<~XSD
          <?xml version="1.0" encoding="UTF-8"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:complexType name="Base">
              <xs:sequence>
                <xs:element name="field" type="xs:string"/>
              </xs:sequence>
            </xs:complexType>
            <xs:complexType name="Derived">
              <xs:complexContent>
                <xs:extension base="Base">
                  <xs:sequence>
                    <xs:element name="newField" type="xs:string"/>
                  </xs:sequence>
                </xs:extension>
              </xs:complexContent>
            </xs:complexType>
          </xs:schema>
        XSD
        File.write("/tmp/test_has_base.xsd", xsd_content)
        parser = Xseed::Parser::XsdParser.new("/tmp/test_has_base.xsd")
        derived = parser.complex_types.last
        generator = described_class.new(derived, parser, config)
        expect(generator.send(:has_hierarchy?)).to be true
        File.delete("/tmp/test_has_base.xsd")
      end
    end

    context "with simple type" do
      it "returns true when type has restriction base" do
        xsd_content = <<~XSD
          <?xml version="1.0" encoding="UTF-8"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:simpleType name="RestrictedString">
              <xs:restriction base="xs:string">
                <xs:maxLength value="10"/>
              </xs:restriction>
            </xs:simpleType>
          </xs:schema>
        XSD
        File.write("/tmp/test_simple_base.xsd", xsd_content)
        parser = Xseed::Parser::XsdParser.new("/tmp/test_simple_base.xsd")
        simple_type = parser.simple_types.first
        generator = described_class.new(simple_type, parser, config)
        expect(generator.send(:has_hierarchy?)).to be true
        File.delete("/tmp/test_simple_base.xsd")
      end
    end
  end

  describe "configuration options" do
    context "print_all_super_types option" do
      let(:xsd_content) do
        <<~XSD
          <?xml version="1.0" encoding="UTF-8"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:complexType name="Level1">
              <xs:sequence>
                <xs:element name="field1" type="xs:string"/>
              </xs:sequence>
            </xs:complexType>
            <xs:complexType name="Level2">
              <xs:complexContent>
                <xs:extension base="Level1">
                  <xs:sequence>
                    <xs:element name="field2" type="xs:string"/>
                  </xs:sequence>
                </xs:extension>
              </xs:complexContent>
            </xs:complexType>
            <xs:complexType name="Level3">
              <xs:complexContent>
                <xs:extension base="Level2">
                  <xs:sequence>
                    <xs:element name="field3" type="xs:string"/>
                  </xs:sequence>
                </xs:extension>
              </xs:complexContent>
            </xs:complexType>
          </xs:schema>
        XSD
      end

      it "shows all supertypes when enabled" do
        File.write("/tmp/test_all_super.xsd", xsd_content)
        parser = Xseed::Parser::XsdParser.new("/tmp/test_all_super.xsd")
        config.print_all_super_types = true
        level3 = parser.complex_types.last
        generator = described_class.new(level3, parser, config)
        result = generator.generate
        # When print_all_super_types is true, should show full hierarchy
        expect(result).to include("Super-type")
        File.delete("/tmp/test_all_super.xsd")
      end

      it "shows only parent type when disabled" do
        File.write("/tmp/test_parent_only.xsd", xsd_content)
        parser = Xseed::Parser::XsdParser.new("/tmp/test_parent_only.xsd")
        config.print_all_super_types = false
        level3 = parser.complex_types.last
        generator = described_class.new(level3, parser, config)
        result = generator.generate
        # When print_all_super_types is false, should show "Parent type"
        expect(result).to include("Parent type")
        File.delete("/tmp/test_parent_only.xsd")
      end
    end

    context "print_all_sub_types option" do
      let(:xsd_content) do
        <<~XSD
          <?xml version="1.0" encoding="UTF-8"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:complexType name="Base">
              <xs:sequence>
                <xs:element name="field" type="xs:string"/>
              </xs:sequence>
            </xs:complexType>
            <xs:complexType name="Child1">
              <xs:complexContent>
                <xs:extension base="Base">
                  <xs:sequence>
                    <xs:element name="child1Field" type="xs:string"/>
                  </xs:sequence>
                </xs:extension>
              </xs:complexContent>
            </xs:complexType>
            <xs:complexType name="Grandchild">
              <xs:complexContent>
                <xs:extension base="Child1">
                  <xs:sequence>
                    <xs:element name="grandchildField" type="xs:string"/>
                  </xs:sequence>
                </xs:extension>
              </xs:complexContent>
            </xs:complexType>
          </xs:schema>
        XSD
      end

      it "shows all subtypes when enabled" do
        File.write("/tmp/test_all_sub.xsd", xsd_content)
        parser = Xseed::Parser::XsdParser.new("/tmp/test_all_sub.xsd")
        config.print_all_sub_types = true
        base = parser.complex_types.first
        generator = described_class.new(base, parser, config)
        result = generator.generate
        expect(result).to include("Sub-type")
        File.delete("/tmp/test_all_sub.xsd")
      end

      it "shows only direct subtypes when disabled" do
        File.write("/tmp/test_direct_sub.xsd", xsd_content)
        parser = Xseed::Parser::XsdParser.new("/tmp/test_direct_sub.xsd")
        config.print_all_sub_types = false
        base = parser.complex_types.first
        generator = described_class.new(base, parser, config)
        result = generator.generate
        expect(result).to include("Direct sub-type")
        File.delete("/tmp/test_direct_sub.xsd")
      end
    end
  end

  describe "edge cases" do
    it "handles circular type references gracefully" do
      # XSD doesn't typically allow circular references, but test defensive code
      xsd_content = <<~XSD
        <?xml version="1.0" encoding="UTF-8"?>
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
          <xs:complexType name="TypeA">
            <xs:sequence>
              <xs:element name="field" type="xs:string"/>
            </xs:sequence>
          </xs:complexType>
        </xs:schema>
      XSD
      File.write("/tmp/test_circular.xsd", xsd_content)
      parser = Xseed::Parser::XsdParser.new("/tmp/test_circular.xsd")
      type_a = parser.complex_types.first
      generator = described_class.new(type_a, parser, config)
      # Should not raise error
      expect { generator.generate }.not_to raise_error
      File.delete("/tmp/test_circular.xsd")
    end

    it "handles types with no name attribute" do
      doc = Nokogiri::XML("<xs:complexType><xs:sequence/></xs:complexType>")
      type_node = doc.root
      parser = instance_double(Xseed::Parser::XsdParser)
      allow(parser).to receive_messages(complex_types: [], simple_types: [])
      generator = described_class.new(type_node, parser, config)
      result = generator.generate
      expect(result).to be_nil
    end
  end
end
