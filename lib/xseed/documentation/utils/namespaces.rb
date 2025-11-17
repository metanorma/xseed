# frozen_string_literal: true

require "cgi"

module Xseed
  module Documentation
    module Utils
      # Namespaces utility module for handling XSD namespace prefixes
      #
      # This module provides methods for formatting namespace prefixes,
      # generating links to namespace declarations, and collecting namespace
      # information from XML Schemas.
      #
      # Based on XS3P namespaces.xsl utilities.
      module Namespaces
        # Formats a namespace prefix with a trailing colon
        #
        # @param prefix [String, nil] The namespace prefix
        # @return [String] The formatted prefix with colon, or empty string
        #
        # @example
        #   format_namespace_prefix("xs")  #=> "xs:"
        #   format_namespace_prefix("")    #=> ""
        #   format_namespace_prefix(nil)   #=> ""
        def format_namespace_prefix(prefix)
          return "" if prefix.nil? || prefix.strip.empty?

          "#{prefix}:"
        end

        # Generates an HTML link to a namespace declaration
        #
        # @param prefix [String, nil] The namespace prefix
        # @param schema [Object] The schema object with namespaces hash
        # @param schema_loc [String] Optional schema location for external refs
        # @return [String] HTML link element or plain text
        #
        # @example
        #   namespace_link("xs", schema)
        #   #=> "<a href=\"#ns-xs\" title=\"...\">xs</a>"
        def namespace_link(prefix, schema, schema_loc: nil)
          return "" if prefix.nil? || prefix.strip.empty?

          namespaces = schema&.namespaces || {}

          if namespaces.key?(prefix)
            # Known namespace - create link to declaration
            href = if schema_loc && schema_loc != "this"
                     "#{schema_loc}##{namespace_anchor_id(prefix)}"
                   else
                     "##{namespace_anchor_id(prefix)}"
                   end

            namespace_uri = namespaces[prefix]
            title = "Find out namespace of '#{prefix}' prefix: #{namespace_uri}"

            "<a href=\"#{CGI.escape_html(href)}\" " \
              "title=\"#{CGI.escape_html(title)}\">#{CGI.escape_html(prefix)}</a>"
          else
            # Unknown namespace - create warning link
            warning = "Unknown namespace prefix: #{prefix}"
            "<a href=\"javascript:void(0)\" " \
              "onclick=\"alert('#{CGI.escape_html(warning)}')\" " \
              "title=\"#{CGI.escape_html(warning)}\">#{CGI.escape_html(prefix)}</a>"
          end
        end

        # Formats a namespace prefix with optional link and colon
        #
        # @param prefix [String, nil] The namespace prefix
        # @param schema [Object] The schema object with namespaces hash
        # @param link [Boolean] Whether to generate a link (default: true)
        # @param schema_loc [String] Optional schema location for external refs
        # @return [String] Formatted prefix with colon, optionally linked
        #
        # @example
        #   format_namespace_with_prefix("xs", schema)
        #   #=> "<a href=\"#ns-xs\" title=\"...\">xs</a>:"
        #
        #   format_namespace_with_prefix("xs", schema, link: false)
        #   #=> "xs:"
        def format_namespace_with_prefix(prefix, schema, link: true,
                                         schema_loc: nil)
          return "" if prefix.nil? || prefix.strip.empty?

          if link
            "#{namespace_link(prefix, schema, schema_loc: schema_loc)}:"
          else
            format_namespace_prefix(prefix)
          end
        end

        # Collects all namespaces from a schema
        #
        # @param schema [Object, nil] The schema object with namespaces hash
        # @return [Hash] Hash of prefix => namespace URI mappings
        #
        # @example
        #   collect_namespaces(schema)
        #   #=> { "xs" => "http://www.w3.org/2001/XMLSchema",
        #   #     "tns" => "http://example.com/target" }
        def collect_namespaces(schema)
          return {} if schema.nil?

          namespaces = schema.namespaces
          return {} if namespaces.nil?

          namespaces.dup
        end

        # Generates an anchor ID for a namespace prefix
        #
        # @param prefix [String, nil] The namespace prefix
        # @return [String] The anchor ID for the namespace
        #
        # @example
        #   namespace_anchor_id("xs")  #=> "ns-xs"
        #   namespace_anchor_id("tns") #=> "ns-tns"
        def namespace_anchor_id(prefix)
          "ns-#{prefix}"
        end

        # Formats a namespace declaration (xmlns)
        #
        # @param prefix [String, nil] The namespace prefix (empty for default)
        # @param namespace [String, nil] The namespace URI
        # @return [String] Formatted xmlns declaration
        #
        # @example
        #   format_namespace_declaration("xs", "http://www.w3.org/2001/XMLSchema")
        #   #=> "xmlns:xs=\"http://www.w3.org/2001/XMLSchema\""
        #
        #   format_namespace_declaration("", "http://example.com/default")
        #   #=> "xmlns=\"http://example.com/default\""
        def format_namespace_declaration(prefix, namespace)
          prefix_part = if prefix.nil? || prefix.strip.empty?
                          "xmlns"
                        else
                          "xmlns:#{prefix}"
                        end

          namespace_value = namespace.nil? ? "" : CGI.escape_html(namespace)

          "#{prefix_part}=\"#{namespace_value}\""
        end
      end
    end
  end
end
