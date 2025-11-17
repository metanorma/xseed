# frozen_string_literal: true

# Load all symbol classes
require_relative "symbol/base"
require_relative "symbol/schema_symbol"
require_relative "symbol/element_root_symbol"
require_relative "symbol/loop_symbol"
require_relative "symbol/collapsed_symbol"
require_relative "symbol/type_reference_symbol"
require_relative "symbol/element_symbol"
require_relative "symbol/complex_type_symbol"
require_relative "symbol/simple_type_symbol"
require_relative "symbol/attribute_symbol"
require_relative "symbol/sequence_symbol"
require_relative "symbol/choice_symbol"
require_relative "symbol/all_symbol"
require_relative "symbol/group_symbol"
require_relative "symbol/attribute_group_symbol"
require_relative "symbol/extension_symbol"
require_relative "symbol/restriction_symbol"
require_relative "symbol/union_symbol"
require_relative "symbol/list_symbol"
require_relative "symbol/notation_symbol"
require_relative "symbol/any_symbol"
require_relative "symbol/any_attribute_symbol"
require_relative "symbol/key_symbol"
require_relative "symbol/unique_symbol"
require_relative "symbol/keyref_symbol"
require_relative "symbol/selector_symbol"
require_relative "symbol/field_symbol"

module Xseed
  module Svg
    # SVG Symbol module containing all XSD symbol representations
    module Symbol
      # Symbol type mapping for factory pattern
      SYMBOL_CLASSES = {
        "schema" => SchemaSymbol,
        "element_root" => ElementRootSymbol,
        "loop" => LoopSymbol,
        "type_reference" => TypeReferenceSymbol,
        "element" => ElementSymbol,
        "complexType" => ComplexTypeSymbol,
        "simpleType" => SimpleTypeSymbol,
        "attribute" => AttributeSymbol,
        "sequence" => SequenceSymbol,
        "choice" => ChoiceSymbol,
        "all" => AllSymbol,
        "group" => GroupSymbol,
        "attributeGroup" => AttributeGroupSymbol,
        "extension" => ExtensionSymbol,
        "restriction" => RestrictionSymbol,
        "union" => UnionSymbol,
        "list" => ListSymbol,
        "notation" => NotationSymbol,
        "any" => AnySymbol,
        "anyAttribute" => AnyAttributeSymbol,
        "key" => KeySymbol,
        "unique" => UniqueSymbol,
        "keyref" => KeyrefSymbol,
        "selector" => SelectorSymbol,
        "field" => FieldSymbol
      }.freeze
    end
  end
end
