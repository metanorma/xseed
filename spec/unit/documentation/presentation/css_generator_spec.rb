# frozen_string_literal: true

require "spec_helper"
require "xseed/documentation/presentation/css_generator"
require "xseed/documentation/config"

RSpec.describe Xseed::Documentation::Presentation::CssGenerator do
  let(:config) { Xseed::Documentation::Config.new }
  let(:generator) { described_class.new(config) }

  describe "#initialize" do
    it "accepts a configuration object" do
      expect(generator).to be_a(described_class)
    end
  end

  describe "#generate" do
    let(:css) { generator.generate }

    context "basic structure" do
      it "returns a string" do
        expect(css).to be_a(String)
      end

      it "is not empty" do
        expect(css).not_to be_empty
      end

      it "contains CSS comment header" do
        expect(css).to include("XSD Documentation Styles")
      end
    end

    context "body styles" do
      it "includes body font and layout styles" do
        expect(css).to match(/body\s*\{/)
        expect(css).to include("font-family")
      end

      it "includes body margins for navigation" do
        expect(css).to include("margin-left")
      end
    end

    context "navigation styles" do
      it "includes navigation sidebar styles" do
        expect(css).to match(/#toc\s*\{/)
      end

      it "includes nav element styles" do
        expect(css).to match(/nav\s*\{/)
      end

      it "includes TOC list styles" do
        expect(css).to match(/#toc\s+ul/)
      end

      it "includes active navigation item styles" do
        expect(css).to include("toc-active")
      end

      it "includes hover effects" do
        expect(css).to match(/hover/)
      end
    end

    context "table styles" do
      it "includes table border collapse" do
        expect(css).to match(/table\s*\{/)
        expect(css).to include("border-collapse")
      end

      it "includes properties table styles" do
        expect(css).to include("properties")
      end

      it "includes table header styles" do
        expect(css).to match(/th\s*\{/)
      end

      it "includes table cell styles" do
        expect(css).to match(/td\s*\{/)
      end
    end

    context "content display styles" do
      it "includes hierarchy display styles" do
        expect(css).to include("hierarchy")
      end

      it "includes instance sample styles" do
        expect(css).to include("instance-sample")
      end

      it "includes XML code display styles" do
        expect(css).to include("xml-code")
      end

      it "includes pre-formatted text styles" do
        expect(css).to match(/pre\s*\{/)
      end
    end

    context "responsive design" do
      it "includes media queries" do
        expect(css).to match(/@media/)
      end

      it "includes mobile viewport breakpoints" do
        expect(css).to match(/@media.*768px/)
      end

      it "includes print styles" do
        expect(css).to match(/@media.*print/)
      end
    end

    context "XS3P specific styles" do
      it "includes XS3P sidenav styles" do
        expect(css).to include("xs3p-sidenav")
      end

      it "includes panel styles" do
        expect(css).to include("panel")
      end

      it "includes callout styles" do
        expect(css).to include("bs-callout")
      end

      it "includes collapse button styles" do
        expect(css).to include("xs3p-collapse-button")
      end
    end

    context "syntax highlighting" do
      it "includes syntax highlight classes" do
        expect(css).to include("codehilite")
      end

      it "includes error highlighting" do
        expect(css).to match(/\.codehilite\s+\.err/)
      end

      it "includes comment highlighting" do
        expect(css).to match(/\.codehilite\s+\.c/)
      end
    end

    context "layout sections" do
      it "includes main content padding" do
        expect(css).to match(/main\s*\{/)
        expect(css).to include("padding")
      end

      it "includes title section styles" do
        expect(css).to include("title-section")
      end

      it "includes section spacing" do
        expect(css).to match(/section/)
      end
    end

    context "toggle button" do
      it "includes toggle element styles" do
        expect(css).to match(/#toggle/)
      end

      it "includes toggle positioning" do
        expect(css).to include("#toggle")
        expect(css).to match(/position:\s*fixed/)
      end
    end
  end

  describe "#external_css_url" do
    context "when no external CSS is configured" do
      it "returns nil" do
        expect(generator.external_css_url).to be_nil
      end
    end

    context "when external CSS is configured" do
      before do
        config.external_css_url = "https://example.com/custom.css"
      end

      it "returns the configured URL" do
        expect(generator.external_css_url).to eq("https://example.com/custom.css")
      end
    end
  end

  describe "CSS validity" do
    let(:css) { generator.generate }

    it "does not contain unclosed braces" do
      open_braces = css.scan(/{/).count
      close_braces = css.scan(/}/).count
      expect(open_braces).to eq(close_braces)
    end

    it "does not contain obvious syntax errors" do
      # Check for common CSS syntax errors
      expect(css).not_to match(/;;/) # Double semicolons
      expect(css).not_to match(/:\s*;/) # Empty property values
    end
  end
end
