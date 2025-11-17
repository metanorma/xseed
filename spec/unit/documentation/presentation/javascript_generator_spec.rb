# frozen_string_literal: true

require "spec_helper"
require "xseed/documentation/presentation/javascript_generator"
require "xseed/documentation/config"

RSpec.describe Xseed::Documentation::Presentation::JavascriptGenerator do
  let(:config) { Xseed::Documentation::Config.new }
  let(:generator) { described_class.new(config) }

  describe "#initialize" do
    it "accepts a configuration object" do
      expect(generator).to be_a(described_class)
    end
  end

  describe "#generate" do
    let(:js) { generator.generate }

    context "basic structure" do
      it "returns a string" do
        expect(js).to be_a(String)
      end

      it "is not empty" do
        expect(js).not_to be_empty
      end

      it "contains JavaScript comment header" do
        expect(js).to include("XSD Documentation JavaScript")
      end
    end

    context "TOC toggle functionality" do
      it "includes TOC toggle function" do
        expect(js).to include("initializeTOC")
      end

      it "includes jQuery click handler for toggle" do
        expect(js).to match(/\$\(['"]#toggle['"]\)/)
      end

      it "includes navigation show/hide logic" do
        expect(js).to match(/\$\(['"]nav['"]\)/)
      end

      it "includes animation duration" do
        expect(js).to include("duration")
      end
    end

    context "tooltip and popover initialization" do
      it "includes tooltip initialization" do
        expect(js).to include("tooltip")
      end

      it "includes popover initialization" do
        expect(js).to include("popover")
      end

      it "includes data-toggle selector" do
        expect(js).to match(/data-toggle/)
      end
    end

    context "smooth scrolling" do
      it "includes smooth scroll initialization" do
        expect(js).to include("initializeSmoothScroll")
      end
    end

    context "markdown processing" do
      it "includes Markdown converter" do
        expect(js).to include("Markdown.Converter")
      end

      it "includes documentation processing" do
        expect(js).to match(/xs3p-doc/)
      end
    end

    context "modal handling" do
      it "includes modal click handler" do
        expect(js).to match(/modal/)
      end
    end

    context "DOMContentLoaded event" do
      it "includes DOMContentLoaded listener" do
        expect(js).to include("DOMContentLoaded")
      end

      it "calls initialization functions" do
        expect(js).to include("initializeTOC")
        expect(js).to include("initializeTooltips")
        expect(js).to include("initializeSmoothScroll")
      end
    end

    context "sidebar scrolling" do
      it "includes sidebar position logic" do
        expect(js).to match(/xs3p-sidebar/)
      end

      it "includes window scroll handler" do
        expect(js).to match(/window.*scroll/)
      end

      it "includes resize handler" do
        expect(js).to match(/window.*resize/)
      end
    end
  end

  describe "#jquery_url" do
    context "when using default jQuery" do
      it "returns the configured jQuery URL" do
        expect(generator.jquery_url).to include("jquery")
      end

      it "returns a valid URL" do
        expect(generator.jquery_url).to match(%r{^https?://})
      end
    end

    context "when custom jQuery URL is configured" do
      before do
        config.jquery_url = "https://example.com/jquery.min.js"
      end

      it "returns the custom URL" do
        expect(generator.jquery_url).to eq("https://example.com/jquery.min.js")
      end
    end
  end

  describe "#bootstrap_url" do
    context "when using default Bootstrap" do
      it "returns the configured Bootstrap URL" do
        expect(generator.bootstrap_url).to include("bootstrap")
      end

      it "returns a valid URL" do
        expect(generator.bootstrap_url).to match(%r{^https?://})
      end
    end

    context "when custom Bootstrap URL is configured" do
      before do
        config.bootstrap_url = "https://example.com/bootstrap"
      end

      it "returns the custom URL" do
        expect(generator.bootstrap_url).to eq("https://example.com/bootstrap")
      end
    end
  end

  describe "JavaScript validity" do
    let(:js) { generator.generate }

    it "does not contain unclosed braces" do
      open_braces = js.scan(/{/).count
      close_braces = js.scan(/}/).count
      expect(open_braces).to eq(close_braces)
    end

    it "does not contain unclosed parentheses" do
      open_parens = js.scan("(").count
      close_parens = js.scan(")").count
      expect(open_parens).to eq(close_parens)
    end
  end
end
