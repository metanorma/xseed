# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/xseed/svg/svg_renderer"
require_relative "../../../lib/xseed/svg/symbol"

RSpec.describe Xseed::Svg::SvgRenderer, "P2 Polish Features" do
  let(:root_symbol) do
    Xseed::Svg::Symbol::ElementSymbol.new(
      name: "root",
      type: "element",
      xsd_node: double("xsd_node", namespace: "ns", documentation: "Root element")
    )
  end
  let(:renderer) { described_class.new(root_symbol) }

  describe "Feature 7: Rounded Rectangle Shadows" do
    it "renders shadow with rounded corners (rx/ry=5)" do
      svg = renderer.render
      expect(svg).to include('class="shadow"')
      expect(svg).to include('rx="5"')
      expect(svg).to include('ry="5"')
    end

    it "renders main shape with rounded corners" do
      svg = renderer.render
      expect(svg).to include('class="symbol-shape')
      expect(svg).to match(/rx="5".*ry="5"/)
    end
  end

  describe "Feature 6: Big Font for Special Characters" do
    context "with attribute symbol starting with @" do
      let(:attribute_symbol) do
        Xseed::Svg::Symbol::AttributeSymbol.new(
          name: "@id",
          type: "attribute",
          xsd_node: double("xsd_node")
        )
      end
      let(:renderer) { described_class.new(attribute_symbol) }

      it "renders @ symbol in larger font (16px)" do
        svg = renderer.render
        expect(svg).to include('font-size="16"')
        expect(svg).to include('class="special-char"')
      end

      it "renders @ symbol in bold" do
        svg = renderer.render
        expect(svg).to include('font-weight="bold"')
      end

      it "renders remaining text in regular font" do
        svg = renderer.render
        expect(svg).to include('font-size="12"')
      end
    end
  end

  describe "Feature 5: Element Anchor Links" do
    context "with type reference" do
      let(:element_with_type) do
        symbol = Xseed::Svg::Symbol::ElementSymbol.new(
          name: "person",
          type: "element",
          xsd_node: double("xsd_node")
        )
        allow(symbol).to receive(:type_info).and_return("PersonType")
        symbol
      end
      let(:renderer) { described_class.new(element_with_type) }

      it "creates anchor link to type definition" do
        svg = renderer.render
        expect(svg).to include('xlink:href="#sym_type_PersonType"')
      end

      it "styles link with underline" do
        svg = renderer.render
        expect(svg).to include('text-decoration: underline')
      end

      it "uses link color" do
        svg = renderer.render
        expect(svg).to include('fill="#0000EE"')
      end

      it "adds cursor pointer style" do
        svg = renderer.render
        expect(svg).to include('cursor: pointer')
      end
    end
  end

  describe "Feature 2: Interactive Expand/Collapse" do
    context "with children" do
      before do
        child = Xseed::Svg::Symbol::ElementSymbol.new(
          name: "child",
          type: "element",
          xsd_node: double("xsd_node")
        )
        root_symbol.add_child(child)
      end

      it "renders collapse button" do
        svg = renderer.render
        expect(svg).to include('class="collapse-button"')
      end

      it "renders button with onclick handler" do
        svg = renderer.render
        expect(svg).to match(/onclick="toggleChildren\('sym_\d+'\)"/)
      end

      it "renders circular button" do
        svg = renderer.render
        expect(svg).to include('<circle')
        expect(svg).to include('r="7"')
      end

      it "renders minus sign in button" do
        svg = renderer.render
        expect(svg).to include('>-<')
      end

      it "wraps children in group with ID" do
        svg = renderer.render
        expect(svg).to match(/<g id="sym_\d+_children" class="child-group">/)
      end
    end

    context "without children" do
      it "does not render collapse button" do
        svg = renderer.render
        expect(svg).not_to include('class="collapse-button"')
      end
    end
  end

  describe "Feature 4: Menu Buttons" do
    it "renders menu button for all symbols" do
      svg = renderer.render
      expect(svg).to include('class="menu-button"')
    end

    it "renders three-dot menu icon" do
      svg = renderer.render
      # Should have 3 circles for dots
      menu_section = svg.match(/<g class="menu-button".*?<\/g>/m)
      expect(menu_section).not_to be_nil
      expect(menu_section.to_s.scan(/<circle/).size).to eq(3)
    end

    it "positions menu button at top-right" do
      svg = renderer.render
      # Menu button has transform to position right
      expect(svg).to match(/class="menu-button".*?transform="translate\(\d+, 5\)"/m)
    end

    it "adds cursor pointer to menu button" do
      svg = renderer.render
      expect(svg).to match(/class="menu-button".*?cursor: pointer/m)
    end
  end

  describe "Feature 3: Alternate Drawing Modes (MouseOver)" do
    it "includes JavaScript for mouseover effects" do
      svg = renderer.render
      expect(svg).to include('<script>')
      expect(svg).to include('mouseenter')
      expect(svg).to include('mouseleave')
      expect(svg).to include('symbol-hover')
    end

    it "includes CSS for hover effects" do
      svg = renderer.render
      expect(svg).to include('.symbol-hover')
      expect(svg).to include('stroke-width: 3')
      expect(svg).to include('drop-shadow')
    end

    it "adds transition for smooth hover effect" do
      svg = renderer.render
      expect(svg).to include('transition')
    end
  end

  describe "JavaScript Integration" do
    it "includes JavaScript code block" do
      svg = renderer.render
      expect(svg).to include('<script>')
      expect(svg).to include('</script>')
    end

    it "includes toggleChildren function" do
      svg = renderer.render
      expect(svg).to include('function toggleChildren')
    end

    it "toggles display of child groups" do
      svg = renderer.render
      expect(svg).to include('childGroup.style.display')
    end

    it "updates button text on toggle" do
      svg = renderer.render
      expect(svg).to include("button.textContent = isHidden ? '-' : '+'")
    end

    it "includes DOMContentLoaded listener" do
      svg = renderer.render
      expect(svg).to include('DOMContentLoaded')
    end
  end

  describe "CSS Enhancements" do
    it "includes collapse button hover styles" do
      svg = renderer.render
      expect(svg).to include('.collapse-button:hover')
    end

    it "includes menu button hover styles" do
      svg = renderer.render
      expect(svg).to include('.menu-button:hover')
    end

    it "includes type link hover styles" do
      svg = renderer.render
      expect(svg).to include('.type-link:hover')
    end

    it "includes special character styles" do
      svg = renderer.render
      expect(svg).to include('.special-char')
    end

    it "includes child group display control" do
      svg = renderer.render
      expect(svg).to include('.child-group')
      expect(svg).to include('display: block')
    end
  end

  describe "Feature 1: Selector and Field Symbol Support" do
    context "with key constraint having selector and fields" do
      let(:key_symbol) do
        selector_node = double("selector", "xpath" => "./element")
        field_node = double("field", "xpath" => "@id")
        xsd_node = double("xsd_node",
                          selector: selector_node,
                          field: [field_node])

        Xseed::Svg::Symbol::KeySymbol.new(name: "pk", xsd_node: xsd_node)
      end
      let(:renderer) { described_class.new(key_symbol) }

      it "creates selector child symbol" do
        expect(key_symbol.children.size).to eq(2)
        selector = key_symbol.children.find { |c| c.type == "selector" }
        expect(selector).not_to be_nil
        expect(selector.name).to eq("selector: ./element")
      end

      it "creates field child symbols" do
        field = key_symbol.children.find { |c| c.type == "field" }
        expect(field).not_to be_nil
        expect(field.name).to eq("field: @id")
      end

      it "renders selector and field in SVG" do
        svg = renderer.render
        expect(svg).to include('selector:')
        expect(svg).to include('field:')
      end

      it "applies correct CSS classes to selector/field" do
        svg = renderer.render
        expect(svg).to include('xsd-selector')
        expect(svg).to include('xsd-field')
      end
    end
  end

  describe "SVG Structure" do
    it "includes xmlns:xlink namespace" do
      svg = renderer.render
      expect(svg).to include('xmlns:xlink="http://www.w3.org/1999/xlink"')
    end

    it "assigns unique IDs to symbols" do
      child = Xseed::Svg::Symbol::ElementSymbol.new(
        name: "child",
        type: "element",
        xsd_node: double("xsd_node")
      )
      root_symbol.add_child(child)

      svg = renderer.render
      # Should have sym_ prefixed IDs
      expect(svg).to match(/id="sym_\d+"/)
    end

    it "includes data-name attribute for symbols" do
      svg = renderer.render
      expect(svg).to include('data-name="root"')
    end
  end
end