# frozen_string_literal: true

require_relative "xseed/version"

module Xseed
  class Error < StandardError; end
  class ParserError < Error; end
  class GenerationError < Error; end

  autoload :CLI, "xseed/cli"

  module Parser
    autoload :XsdParser, "xseed/parser/xsd_parser"
    autoload :SchemaParser, "xseed/parser/schema_parser"
    autoload :NamespaceResolver, "xseed/parser/namespace_resolver"
    autoload :AnnotationExtractor, "xseed/parser/annotation_extractor"
  end

  module Models
    autoload :Schema, "xseed/models/schema"
    autoload :Element, "xseed/models/element"
    autoload :ComplexType, "xseed/models/complex_type"
    autoload :SimpleType, "xseed/models/simple_type"
    autoload :Attribute, "xseed/models/attribute"
    autoload :Group, "xseed/models/group"
  end

  module SVG
    autoload :Generator, "xseed/svg/generator"

    module Symbols
      autoload :Base, "xseed/svg/symbols/base"
    end
  end

  module Svg
    autoload :SvgGenerator, "xseed/svg/svg_generator"
    autoload :LayoutEngine, "xseed/svg/layout_engine"
    autoload :SvgRenderer, "xseed/svg/svg_renderer"
    autoload :SymbolFactory, "xseed/svg/symbol_factory"

    module Symbol
      autoload :Base, "xseed/svg/symbol/base"
      autoload :SchemaSymbol, "xseed/svg/symbol/schema_symbol"
      autoload :LoopSymbol, "xseed/svg/symbol/loop_symbol"
      autoload :ElementSymbol, "xseed/svg/symbol/element_symbol"
      autoload :ComplexTypeSymbol, "xseed/svg/symbol/complex_type_symbol"
      autoload :SimpleTypeSymbol, "xseed/svg/symbol/simple_type_symbol"
      autoload :AttributeSymbol, "xseed/svg/symbol/attribute_symbol"
      autoload :SequenceSymbol, "xseed/svg/symbol/sequence_symbol"
      autoload :ChoiceSymbol, "xseed/svg/symbol/choice_symbol"
      autoload :AllSymbol, "xseed/svg/symbol/all_symbol"
      autoload :GroupSymbol, "xseed/svg/symbol/group_symbol"
      autoload :AttributeGroupSymbol, "xseed/svg/symbol/attribute_group_symbol"
      autoload :ExtensionSymbol, "xseed/svg/symbol/extension_symbol"
      autoload :RestrictionSymbol, "xseed/svg/symbol/restriction_symbol"
      autoload :UnionSymbol, "xseed/svg/symbol/union_symbol"
      autoload :ListSymbol, "xseed/svg/symbol/list_symbol"
      autoload :NotationSymbol, "xseed/svg/symbol/notation_symbol"
      autoload :AnySymbol, "xseed/svg/symbol/any_symbol"
    end

    module Layout
      autoload :BoxCalculator, "xseed/svg/layout/box_calculator"
      autoload :PositionManager, "xseed/svg/layout/position_manager"
    end

    module Renderer
      autoload :DocumentBuilder, "xseed/svg/renderer/document_builder"
      autoload :StyleManager, "xseed/svg/renderer/style_manager"
      autoload :ScriptManager, "xseed/svg/renderer/script_manager"
    end
  end

  module Documentation
    autoload :Generator, "xseed/documentation/generator"
    autoload :HtmlGenerator, "xseed/documentation/html_generator"
    autoload :Config, "xseed/documentation/config"

    module Core
      autoload :Parameters, "xseed/documentation/core/parameters"
      autoload :Constants, "xseed/documentation/core/constants"
    end

    module Utilities
      autoload :StringHelpers, "xseed/documentation/utilities/string_helpers"
      autoload :NamespaceHelpers,
               "xseed/documentation/utilities/namespace_helpers"
      autoload :ReferenceResolver,
               "xseed/documentation/utilities/reference_resolver"
      autoload :SchemaLocationHelper,
               "xseed/documentation/utilities/schema_location_helper"
    end

    module Renderers
      autoload :XMLPrettyPrinter,
               "xseed/documentation/renderers/xml_pretty_printer"
      autoload :GlossaryRenderer,
               "xseed/documentation/renderers/glossary_renderer"
      autoload :UIComponentRenderer,
               "xseed/documentation/renderers/ui_component_renderer"
    end

    module Sections
      autoload :ComponentLinks,
               "xseed/documentation/sections/component_links"
      autoload :HierarchyTables,
               "xseed/documentation/sections/hierarchy_tables"
      autoload :PropertiesTables,
               "xseed/documentation/sections/properties_tables"
      autoload :SchemaComponents,
               "xseed/documentation/sections/schema_components"
    end

    module Presentation
      autoload :HTMLDocument,
               "xseed/documentation/presentation/html_document"
      autoload :Navigation, "xseed/documentation/presentation/navigation"
      autoload :CSSStyles, "xseed/documentation/presentation/css_styles"
      autoload :JavaScript, "xseed/documentation/presentation/javascript"
    end
  end
end
