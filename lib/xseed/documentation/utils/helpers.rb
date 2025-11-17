# frozen_string_literal: true

require "cgi"

module Xseed
  module Documentation
    module Utils
      # Helpers utility module for common formatting and component utilities
      #
      # This module provides methods for formatting schema component descriptions,
      # generating anchor IDs, formatting occurrences, URIs, boolean values, and
      # various XSD-specific sets.
      #
      # Based on XS3P common-helpers.xsl utilities.
      module Helpers
        # Component type prefixes for anchor IDs
        COMPONENT_PREFIXES = {
          "attribute" => "attr-",
          "attributeGroup" => "attrgrp-",
          "complexType" => "ctype-",
          "element" => "elem-",
          "group" => "grp-",
          "notation" => "nota-",
          "simpleType" => "stype-",
          "key" => "key-",
          "unique" => "key-"
        }.freeze

        # Returns a human-readable description for a schema component type
        #
        # @param component_type [String] The component type (e.g., "element", "complexType")
        # @return [String] Human-readable description
        #
        # @example
        #   component_description("element")     #=> "Element"
        #   component_description("complexType") #=> "Complex Type"
        def component_description(component_type)
          case component_type
          when "attribute" then "Attribute"
          when "attributeGroup" then "Attribute Group"
          when "complexType" then "Complex Type"
          when "element" then "Element"
          when "simpleType" then "Simple Type"
          when "group" then "Model Group"
          when "notation" then "Notation"
          when "all" then "All Model Group"
          when "choice" then "Choice Model Group"
          when "sequence" then "Sequence Model Group"
          else "Unknown Component"
          end
        end

        # Generates a unique anchor ID for a schema component
        #
        # @param component_type [String] The component type
        # @param name [String, nil] The component name
        # @return [String] The generated anchor ID
        #
        # @example
        #   generate_component_id("element", "Person") #=> "elem-Person"
        #   generate_component_id("schema", nil)       #=> "schema"
        def generate_component_id(component_type, name)
          return "schema" if component_type == "schema"

          prefix = COMPONENT_PREFIXES[component_type] || "comp-"
          "#{prefix}#{name}"
        end

        # Formats min/max occurrences as [min..max]
        #
        # @param min_occurs [Integer, String, nil] Minimum occurrences (default: 1)
        # @param max_occurs [Integer, String, nil] Maximum occurrences (default: 1)
        # @return [String] Formatted occurrence string
        #
        # @example
        #   format_occurs(1, 1)           #=> "[1]"
        #   format_occurs(0, "unbounded") #=> "[0..*]"
        #   format_occurs(1, 5)           #=> "[1..5]"
        def format_occurs(min_occurs, max_occurs)
          min = min_occurs.nil? ? 1 : min_occurs.to_i
          max = if max_occurs == "unbounded"
                  "*"
                elsif max_occurs.nil?
                  1
                else
                  max_occurs.to_i
                end

          if min == 1 && max == 1
            "[1]"
          else
            "[#{min}..#{max}]"
          end
        end

        # Formats a URI, creating a clickable link for HTTP/HTTPS URIs
        #
        # @param uri [String, nil] The URI to format
        # @return [String] Formatted URI (HTML link or plain text)
        #
        # @example
        #   format_uri("http://example.com")
        #   #=> "<a href=\"http://example.com\" title=\"http://example.com\">http://example.com</a>"
        #
        #   format_uri("schema.xsd")
        #   #=> "schema.xsd"
        def format_uri(uri)
          return "" if uri.nil? || uri.empty?

          if uri.start_with?("http://", "https://")
            escaped_uri = CGI.escape_html(uri)
            "<a href=\"#{escaped_uri}\" title=\"#{escaped_uri}\">#{escaped_uri}</a>"
          else
            uri
          end
        end

        # Formats a boolean value as "yes" or "no"
        #
        # @param value [Boolean, String, Integer, nil] The boolean value
        # @return [String] "yes" or "no"
        #
        # @example
        #   format_boolean(true)    #=> "yes"
        #   format_boolean("true")  #=> "yes"
        #   format_boolean(1)       #=> "yes"
        #   format_boolean(false)   #=> "no"
        #   format_boolean(nil)     #=> "no"
        def format_boolean(value)
          return "no" if value.nil?

          normalized = value.to_s.downcase.strip
          if %w[true 1].include?(normalized)
            "yes"
          else
            "no"
          end
        end

        # Formats a block attribute set, expanding #all
        #
        # @param value [String, nil] The block value
        # @return [String] Formatted block set
        #
        # @example
        #   format_block_set("#all")
        #   #=> "restriction, extension, substitution"
        #
        #   format_block_set("restriction")
        #   #=> "restriction"
        def format_block_set(value)
          return "" if value.nil? || value.strip.empty?

          if value.strip == "#all"
            "restriction, extension, substitution"
          else
            value
          end
        end

        # Formats a derivation set, expanding #all
        #
        # @param value [String, nil] The derivation value
        # @return [String] Formatted derivation set
        #
        # @example
        #   format_derivation_set("#all")
        #   #=> "restriction, extension"
        #
        #   format_derivation_set("restriction")
        #   #=> "restriction"
        def format_derivation_set(value)
          return "" if value.nil? || value.strip.empty?

          if value.strip == "#all"
            "restriction, extension"
          else
            value
          end
        end

        # Formats a simple type derivation set, expanding #all
        #
        # @param value [String, nil] The derivation value
        # @return [String] Formatted simple derivation set
        #
        # @example
        #   format_simple_derivation_set("#all")
        #   #=> "restriction, list, union"
        #
        #   format_simple_derivation_set("restriction")
        #   #=> "restriction"
        def format_simple_derivation_set(value)
          return "" if value.nil? || value.strip.empty?

          if value.strip == "#all"
            "restriction, list, union"
          else
            value
          end
        end
      end
    end
  end
end
