# frozen_string_literal: true

module Xseed
  module Documentation
    # Constants used throughout HTML documentation generation
    # Ported from xs3p core/constants.xsl
    module Constants
      # XML Schema Namespace
      XSD_NS = "http://www.w3.org/2001/XMLSchema"

      # XML Namespace
      XML_NS = "http://www.w3.org/XML/1998/namespace"

      # Number of spaces to indent from parent element's start tag to
      # child element's start tag
      ELEM_INDENT = 3

      # Number of spaces to indent from parent element's start tag to
      # attribute's tag
      ATTR_INDENT = 2

      # Title to use if none provided
      DEFAULT_TITLE = "XML Schema Documentation"

      # Prefixes used for anchor names
      # Type definitions (both complex and simple)
      TYPE_PREFIX = "type_"
      # Attribute declarations
      ATTR_PREFIX = "attribute_"
      # Attribute group definitions
      ATTR_GROUP_PREFIX = "attributeGroup_"
      # Element declarations
      ELEM_PREFIX = "element_"
      # Key definitions
      KEY_PREFIX = "key_"
      # Group definitions
      GROUP_PREFIX = "group_"
      # Notations
      NOTATION_PREFIX = "notation_"
      # Namespace declarations
      NS_PREFIX = "ns_"
      # Glossary terms
      TERM_PREFIX = "term_"

      # Help texts used throughout the document
      # Hierarchy table
      HELP_HIERARCHY = "This table shows the schema components type hierarchy."

      # Properties table
      HELP_PROPERTIES = "This table displays the properties of the schema component."

      # Documentation panel
      HELP_DOCUMENTATION = "This panel contains the schema components documentation."

      # Instance table
      HELP_INSTANCE = <<~HELP.strip
        The XML Instance Representation table shows the schema component's content as an XML instance.
        <ul>
        <li>The minimum and maximum occurrence of elements and attributes are provided in square brackets, e.g. [0..1].</li>
        <li>Model group information are shown in gray, e.g. Start Choice ... End Choice.</li>
        <li>For type derivations, the elements and attributes that have been added to or changed from the base type's content are shown in <strong>bold</strong></li>
        <li>If an element/attribute has a fixed value, the fixed value is shown in green.</li>
        <li>If a local element/attribute has documentation, it will be displayed in a window that pops up when the question mark inside the attribute or next to the element is clicked.</li>
        </ul>
      HELP

      # Representation table
      HELP_REPRESENTATION = "The Schema Component Representation table below displays " \
                            "the underlying XML representation of the schema component. " \
                            "(Annotations are not shown.)"

      # Navigation panel width
      NAV_WIDTH = "270px"
    end
  end
end
