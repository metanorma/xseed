# frozen_string_literal: true

require "spec_helper"
require "xseed/documentation/presentation/navigation_builder"
require "xseed/documentation/config"
require "xseed/parser/xsd_parser"

RSpec.describe Xseed::Documentation::Presentation::NavigationBuilder do
  let(:fixture_path) do
    File.join(__dir__, "../../../fixtures/simple/element_only.xsd")
  end
  let(:parser) { Xseed::Parser::XsdParser.new(fixture_path) }
  let(:config) { Xseed::Documentation::Config.new }
  let(:builder) { described_class.new(parser, config) }

  describe "#initialize" do
    it "accepts a parser and configuration" do
      expect(builder).to be_a(described_class)
    end
  end

  describe "#generate" do
    let(:html) { builder.generate }

    context "structure" do
      it "returns a string" do
        expect(html).to be_a(String)
      end

      it "is not empty" do
        expect(html).not_to be_empty
      end

      it "contains nav element" do
        expect(html).to include("<nav")
      end

      it "contains TOC id" do
        expect(html).to include('id="toc"')
      end

      it "contains unordered list" do
        expect(html).to include("<ul")
      end
    end

    context "schema properties section" do
      it "includes schema properties link" do
        expect(html).to include("Schema")
      end

      it "includes anchor to schema properties" do
        expect(html).to match(/href=["']#.*[Ss]chema.*[Pp]roperties/)
      end
    end

    context "elements section" do
      it "includes elements heading when elements exist" do
        expect(html).to include("Elements") if parser.elements.any?
      end

      it "includes element names as links" do
        parser.elements.each do |element|
          name = element["name"]
          expect(html).to include(name) if name
        end
      end

      it "generates proper element anchor IDs" do
        parser.elements.each do |element|
          name = element["name"]
          next unless name

          expect(html).to match(/href=["']#element-#{Regexp.escape(name)}["']/)
        end
      end
    end

    context "complex types section" do
      it "includes complex types heading when types exist" do
        expect(html).to include("Complex Types") if parser.complex_types.any?
      end

      it "includes complex type names as links" do
        parser.complex_types.each do |type|
          name = type["name"]
          expect(html).to include(name) if name
        end
      end

      it "generates proper complex type anchor IDs" do
        parser.complex_types.each do |type|
          name = type["name"]
          next unless name

          expect(html).to match(/href=["']#.*type-#{Regexp.escape(name)}["']/)
        end
      end
    end

    context "simple types section" do
      it "includes simple types heading when types exist" do
        expect(html).to include("Types") if parser.simple_types.any?
      end

      it "includes simple type names as links" do
        parser.simple_types.each do |type|
          name = type["name"]
          expect(html).to include(name) if name
        end
      end
    end

    context "groups section" do
      it "includes groups heading when groups exist" do
        expect(html).to include("Groups") if parser.groups.any?
      end

      it "includes group names as links" do
        parser.groups.each do |group|
          name = group["name"]
          expect(html).to include(name) if name
        end
      end
    end

    context "attribute groups section" do
      it "includes attribute groups heading when they exist" do
        if parser.attribute_groups.any?
          expect(html).to include("Attribute Groups")
        end
      end

      it "includes attribute group names as links" do
        parser.attribute_groups.each do |group|
          name = group["name"]
          expect(html).to include(name) if name
        end
      end
    end

    context "CSS classes" do
      it "includes navigation CSS classes" do
        expect(html).to include("nav")
      end

      it "includes list CSS classes" do
        expect(html).to match(/nav-list/)
      end

      it "includes sidenav CSS class" do
        expect(html).to include("xs3p-sidenav")
      end

      it "includes sub-item CSS class for components" do
        if parser.elements.any? || parser.complex_types.any?
          expect(html).to include("nav-sub-item")
        end
      end
    end

    context "HTML validity" do
      it "has balanced opening and closing tags for nav" do
        open_nav = html.scan("<nav").count
        close_nav = html.scan("</nav>").count
        expect(open_nav).to eq(close_nav)
      end

      it "has balanced opening and closing tags for ul" do
        open_ul = html.scan("<ul").count
        close_ul = html.scan("</ul>").count
        expect(open_ul).to eq(close_ul)
      end

      it "has balanced opening and closing tags for li" do
        open_li = html.scan("<li").count
        close_li = html.scan("</li>").count
        expect(open_li).to eq(close_li)
      end

      it "has balanced opening and closing tags for a" do
        open_a = html.scan(/<a[^>]*>/).count
        close_a = html.scan("</a>").count
        expect(open_a).to eq(close_a)
      end
    end
  end

  describe "with sorting enabled" do
    before do
      config.sort_by_component = true
    end

    it "generates navigation with sorted components" do
      html = builder.generate
      expect(html).to be_a(String)
      expect(html).not_to be_empty
    end
  end

  describe "with sorting disabled" do
    before do
      config.sort_by_component = false
    end

    it "generates navigation with components in schema order" do
      html = builder.generate
      expect(html).to be_a(String)
      expect(html).not_to be_empty
    end
  end
end
