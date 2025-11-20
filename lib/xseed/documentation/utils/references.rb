# frozen_string_literal: true

module Xseed
  module Documentation
    module Utils
      # References utility module for handling XSD component references
      #
      # This module provides methods for extracting component names, prefixes,
      # and namespaces from qualified and unqualified references in XML Schema.
      #
      # Based on XS3P references.xsl utilities.
      module References
        XSD_NAMESPACE = "http://www.w3.org/2001/XMLSchema"

        # Extracts the local name from a reference
        #
        # @param ref [String, nil] The reference string (e.g., "xs:string" or "SimpleType")
        # @return [String] The local name part of the reference
        #
        # @example
        #   get_ref_name("xs:string")  #=> "string"
        #   get_ref_name("SimpleType") #=> "SimpleType"
        #   get_ref_name(nil)          #=> ""
        def get_ref_name(ref)
          return "" if ref.nil? || ref.empty?

          if ref.include?(":")
            # Extract local name after first colon
            ref.split(":", 2).last
          else
            # No prefix, return as-is
            ref
          end
        end

        # Extracts the namespace prefix from a reference
        #
        # @param ref [String, nil] The reference string (e.g., "xs:string")
        # @return [String] The namespace prefix or empty string if none
        #
        # @example
        #   get_ref_prefix("xs:string")  #=> "xs"
        #   get_ref_prefix("SimpleType") #=> ""
        #   get_ref_prefix(nil)          #=> ""
        def get_ref_prefix(ref)
          return "" if ref.nil? || ref.empty?

          if ref.include?(":")
            # Extract prefix before first colon
            ref.split(":", 2).first
          else
            # No prefix
            ""
          end
        end

        # Resolves the namespace URI from a reference prefix
        #
        # @param ref [String, nil] The reference string (e.g., "xs:string")
        # @param schema [Object] The schema object with namespaces hash
        # @return [String, nil] The resolved namespace URI or nil
        #
        # @example
        #   get_ref_namespace("xs:string", schema) #=> "http://www.w3.org/2001/XMLSchema"
        #   get_ref_namespace("SimpleType", schema) #=> nil
        def get_ref_namespace(ref, schema)
          return nil if ref.nil? || ref.empty? || schema.nil?

          prefix = get_ref_prefix(ref)
          return nil if prefix.empty?

          schema.namespaces[prefix]
        end

        # Returns the declared prefix of the schema's target namespace
        #
        # @param schema [Object] The schema object with target_namespace and namespaces
        # @return [String] The prefix for the target namespace or empty string
        #
        # @example
        #   get_this_prefix(schema) #=> "tns"
        def get_this_prefix(schema)
          return "" if schema.nil? || schema.target_namespace.nil?

          target_ns = schema.target_namespace
          namespaces = schema.namespaces || {}

          # Find the prefix that maps to the target namespace
          prefix = namespaces.find { |_k, v| v == target_ns }&.first
          prefix || ""
        end

        # Returns the declared prefix of the XML Schema namespace
        #
        # @param schema [Object] The schema object with namespaces hash
        # @return [String] The prefix for XSD namespace or empty string
        #
        # @example
        #   get_xsd_prefix(schema) #=> "xs" or "xsd"
        def get_xsd_prefix(schema)
          return "" if schema.nil?

          namespaces = schema.namespaces || {}

          # Find the prefix that maps to the XSD namespace
          prefix = namespaces.find { |_k, v| v == XSD_NAMESPACE }&.first
          prefix || ""
        end

        # Resolves a type reference to its components
        #
        # @param ref [String, nil] The type reference (e.g., "xs:string" or "MyType")
        # @param schema [Object] The schema object with namespaces
        # @return [Hash] Hash with :namespace, :prefix, and :local_name keys
        #
        # @example
        #   resolve_type_ref("xs:string", schema)
        #   #=> { namespace: "http://www.w3.org/2001/XMLSchema",
        #   #     prefix: "xs", local_name: "string" }
        def resolve_type_ref(ref, schema)
          if ref.nil? || ref.empty?
            return { namespace: nil, prefix: "",
                     local_name: "" }
          end

          {
            namespace: get_ref_namespace(ref, schema),
            prefix: get_ref_prefix(ref),
            local_name: get_ref_name(ref),
          }
        end
      end
    end
  end
end
