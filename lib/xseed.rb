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
