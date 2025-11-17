# frozen_string_literal: true

require_relative "base"

module Xseed
  module Svg
    module Symbol
      # Represents an XML Schema complex type definition
      # Handles content models, derivation, and attribute management
      class ComplexTypeSymbol < Base
        attr_accessor :content_model, :base_type, :derivation_method
        attr_reader :attributes

        def initialize(name:, type:, xsd_node:)
          @attributes = []
          super
          extract_complex_type_attributes
        end

        # Returns true if type allows mixed content
        def mixed?
          @mixed ||= extract_boolean("mixed", false)
        end

        # Returns true if type is abstract
        def abstract?
          @abstract ||= extract_boolean("abstract", false)
        end

        # Returns true if type has simple content
        def simple_content?
          @content_model == :simple_content
        end

        # Returns true if type has complex content
        def complex_content?
          @content_model == :complex_content
        end

        # Returns true if type has no content
        def empty_content?
          return true if @content_model == :empty
          return true if @children.empty? && @content_model.nil?

          false
        end

        # Returns true if derived by extension
        def derived_by_extension?
          @derivation_method == :extension
        end

        # Returns true if derived by restriction
        def derived_by_restriction?
          @derivation_method == :restriction
        end

        # Adds attribute to complex type
        def add_attribute(attribute_symbol)
          @attributes << attribute_symbol
          attribute_symbol
        end

        # Returns true if type has attributes
        def has_attributes?
          !@attributes.empty?
        end

        # Returns only element children (excludes attributes)
        def element_children
          @children.select { |child| child.is_a?(ElementSymbol) }
        end

        # Returns block derivation constraints
        def block
          @block ||= extract_attribute("block")
        end

        # Returns final derivation constraints
        def final
          @final ||= extract_attribute("final")
        end

        # Returns display label for SVG rendering
        def display_label
          label = @name.to_s
          indicators = []
          indicators << "abstract" if abstract?
          indicators << "mixed" if mixed?
          label += " (#{indicators.join(', ')})" unless indicators.empty?
          label
        end

        private

        # Extracts complex type specific attributes
        def extract_complex_type_attributes
          # Content model and derivation set by consumers based on structure
        end

        # Extracts boolean attribute
        def extract_boolean(attr_name, default)
          value = extract_attribute(attr_name)
          return default if value.nil?

          value.to_s.downcase == "true"
        end

        # Extracts attribute from XSD node
        def extract_attribute(attr_name)
          return nil unless @xsd_node.respond_to?(:attributes)

          attributes = @xsd_node.attributes
          return nil unless attributes.is_a?(Hash)

          attributes[attr_name]
        end

        # Override calculate_bounds to account for children and attributes
        def calculate_bounds
          super

          # Adjust height based on number of children and attributes
          total_items = @children.size + @attributes.size
          @height = DEFAULT_HEIGHT + (total_items * 25) if total_items.positive?

          # Ensure minimum width for longer type names
          @width = [@width, 150].max
        end
      end
    end
  end
end
