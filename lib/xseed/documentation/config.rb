# frozen_string_literal: true

module Xseed
  module Documentation
    # Configuration class for HTML documentation generation
    # Ported from xs3p core/parameters.xsl
    class Config
      # Title of HTML document
      attr_accessor :title

      # If true, sorts the top-level schema components by type, then name
      # Otherwise, displays components in the order they appear in the schema
      attr_accessor :sort_by_component

      # If true, prints all super-types in the type hierarchy box
      # Otherwise, prints the parent type only
      attr_accessor :print_all_super_types

      # If true, prints all sub-types in the type hierarchy box
      # Otherwise, prints the direct sub-types only
      attr_accessor :print_all_sub_types

      # If true, prints out the Glossary section
      attr_accessor :print_glossary

      # If true, includes SVG diagram references in component sections
      attr_accessor :print_diagrams

      # If true, prints prefix matching namespace of schema components
      # in XML Instance Representation tables
      attr_accessor :print_ns_prefixes

      # If true, searches 'included' schemas for schema components
      # when generating links and XML Instance Representation tables
      attr_accessor :search_included_schemas

      # If true, searches 'imported' schemas for schema components
      # when generating links and XML Instance Representation tables
      attr_accessor :search_imported_schemas

      # File containing the mapping from file locations of external
      # schemas to file locations of their XHTML documentation
      attr_accessor :links_file

      # Base URL for resolving links
      attr_accessor :base_url

      # External CSS stylesheet URL (xs3p specific CSS, not Bootstrap)
      attr_accessor :external_css_url

      # Link to jQuery
      attr_accessor :jquery_url

      # Link base to Bootstrap CSS and JS
      attr_accessor :bootstrap_url

      def initialize
        # Set defaults from xs3p parameters
        @title = nil # Use schema filename if nil
        @sort_by_component = true
        @print_all_super_types = true
        @print_all_sub_types = true
        @print_glossary = true
        @print_diagrams = true
        @print_ns_prefixes = true
        @search_included_schemas = false
        @search_imported_schemas = false
        @links_file = nil
        @base_url = nil
        @external_css_url = nil
        @jquery_url = "https://cdnjs.cloudflare.com/ajax/libs/jquery/2.2.4/jquery.min.js"
        @bootstrap_url = "https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/3.4.1"
      end

      # Returns configuration as a hash
      def to_h
        {
          title: @title,
          sort_by_component: @sort_by_component,
          print_all_super_types: @print_all_super_types,
          print_all_sub_types: @print_all_sub_types,
          print_glossary: @print_glossary,
          print_diagrams: @print_diagrams,
          print_ns_prefixes: @print_ns_prefixes,
          search_included_schemas: @search_included_schemas,
          search_imported_schemas: @search_imported_schemas,
          links_file: @links_file,
          base_url: @base_url,
          external_css_url: @external_css_url,
          jquery_url: @jquery_url,
          bootstrap_url: @bootstrap_url
        }
      end
    end
  end
end
