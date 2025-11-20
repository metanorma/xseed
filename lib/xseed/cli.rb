# frozen_string_literal: true

require "thor"
require "fileutils"
require_relative "documentation/config"
require_relative "documentation/html_generator"
require_relative "version"

module Xseed
  # Command-line interface for Xseed gem
  # Provides commands for generating SVG diagrams and HTML documentation from XSD
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    # Global options
    class_option :verbose,
                 type: :boolean,
                 aliases: "-v",
                 desc: "Enable verbose output"

    desc "svg INPUT_XSD [OPTIONS]", "Generate SVG diagram from XSD schema"
    long_desc <<~DESC
      Generate an SVG diagram visualizing the structure of an XSD schema file.

      This command uses the xsdvi gem for SVG generation.

      Examples:

        # Generate SVG and write to file
        $ xseed svg schema.xsd -o diagram.svg

        # Generate diagram for a single element
        $ xseed svg schema.xsd -r ElementName -o diagram.svg

        # Output SVG to stdout
        $ xseed svg schema.xsd

      For more options, see: https://github.com/metanorma/xsdvi-ruby
    DESC
    option :output,
           aliases: "-o",
           desc: "Output file path (default: stdout)",
           banner: "PATH"
    option :root_node_name,
           aliases: "-r",
           desc: "Root element name to visualize",
           banner: "NAME"
    option :one_node_only,
           type: :boolean,
           desc: "Show only the specified element"
    option :force,
           type: :boolean,
           aliases: "-f",
           desc: "Overwrite output file if it exists"
    def svg(input_xsd)
      require "xsdvi"

      start_time = Time.now

      # Validate input file
      validate_input_file!(input_xsd)

      # Check output file permissions if specified
      validate_output_path!(options[:output]) if options[:output]

      log_verbose "Generating SVG using xsdvi gem"

      # Create xsdvi components using proper Ruby API
      output_path = options[:output] || "/dev/stdout"
      writer = Xsdvi::Utils::Writer.new(output_path)
      builder = Xsdvi::Tree::Builder.new
      handler = Xsdvi::XsdHandler.new(builder)

      # Set options
      handler.root_node_name = options[:root_node_name] if options[:root_node_name]
      handler.one_node_only = options[:one_node_only] if options[:one_node_only]

      # Process XSD file
      handler.process_file(input_xsd)
      root_symbol = builder.root

      # Generate SVG
      generator = Xsdvi::SVG::Generator.new(writer)
      generator.hide_menu_buttons = options[:one_node_only] if options[:one_node_only]

      log_with_progress("Generating SVG diagram") do
        generator.draw(root_symbol)
      end

      if options[:output]
        elapsed = Time.now - start_time
        say "✓ SVG diagram generated: #{options[:output]}", :green
        log_verbose "Generation completed in #{elapsed.round(3)}s"
      end
    rescue LoadError
      error_exit "xsdvi gem not found. Please run: gem install xsdvi"
    rescue ArgumentError => e
      error_exit "Validation error: #{e.message}"
    rescue StandardError => e
      error_exit "SVG generation error: #{e.message}", show_backtrace: true
    end

    desc "html INPUT_XSD [OPTIONS]",
         "Generate HTML documentation from XSD"
    long_desc <<~DESC
      Generate comprehensive HTML documentation from an XSD schema file.

      SVG diagrams are automatically generated for all elements using the xsdvi gem.
      The diagrams are placed in a subdirectory (default: diagrams/) and automatically
      embedded in the HTML with <object> tags.

      Options:
        -o, --output PATH       Output HTML file path
        -t, --title TEXT        Documentation title
        --css PATH              External CSS file to include
        -d, --diagrams-dir DIR  Directory for SVG diagrams (default: diagrams)

      Example:
        $ xseed htm schema.xsd -o docs/index.html

        This generates:
          docs/index.html           (HTML documentation)
          docs/diagrams/*.svg       (SVG diagrams for each element)

      For more information, visit: https://github.com/metanorma/xseed
    DESC
    option :output,
           aliases: "-o",
           desc: "Output file path",
           banner: "PATH"
    option :title,
           aliases: "-t",
           desc: "Documentation title",
           banner: "TEXT"
    option :css,
           desc: "External CSS file",
           banner: "PATH"
    option :diagrams_dir,
           aliases: "-d",
           desc: "Directory for SVG diagrams relative to output (default: diagrams)",
           banner: "DIR"
    option :force,
           type: :boolean,
           aliases: "-f",
           desc: "Overwrite output file if it exists"
    def html(input_xsd)
      start_time = Time.now

      # Validate input file
      validate_input_file!(input_xsd)

      # Check output file permissions if specified
      validate_output_path!(options[:output]) if options[:output]

      # Create config
      config = Xseed::Documentation::Config.new
      config.title = options[:title] if options[:title]
      config.external_css_url = options[:css] if options[:css]
      config.diagrams_dir = options[:diagrams_dir] if options[:diagrams_dir]

      log_verbose "Creating HTML generator for: #{input_xsd}"

      # Create generator
      generator = Xseed::Documentation::HtmlGenerator.new(input_xsd, config)
      log_verbose "HTML generator initialized"

      # Determine output path
      output_path = options[:output]

      if output_path
        # Check if output file exists
        check_output_file_exists!(output_path)

        # Generate and write to file
        log_with_progress("Generating HTML documentation") do
          generator.generate_file(output_path)
        end

        elapsed = Time.now - start_time
        say "✓ HTML documentation generated: #{output_path}", :green
        log_verbose "Generation completed in #{elapsed.round(3)}s"
      else
        # Generate and output to stdout
        log_verbose "Generating HTML to stdout"
        html_content = generator.generate
        say html_content
      end
    rescue ArgumentError => e
      error_exit "Validation error: #{e.message}"
    rescue StandardError => e
      error_exit "HTML generation error: #{e.message}", show_backtrace: true
    end

    desc "version", "Display Xseed version information"
    def version
      say "━" * 60, :cyan
      say "Xseed - XSD Documentation Generator", :cyan
      say "━" * 60, :cyan
      say ""
      say "Version: #{Xseed::VERSION}", :green
      say ""
      say "Features:"
      say "  ✓ HTML documentation generation (native)", :green
      say "  ✓ SVG diagram generation (via xsdvi gem)", :green
      say "  ✓ XSD schema parsing", :green
      say ""
      say "GitHub: https://github.com/metanorma/xseed"
      say "License: BSD-2-Clause"
    end

    desc "info INPUT_XSD", "Display information about an XSD schema"
    long_desc <<~DESC
      Display detailed information about an XSD schema file without generating output.

      Shows:
        • Schema metadata (namespace, version, etc.)
        • Component counts (elements, types, groups)
        • Complexity metrics
        • Estimated generation time

      Example:
        $ xseed info schema.xsd
    DESC
    def info(input_xsd)
      validate_input_file!(input_xsd)

      say "━" * 60, :cyan
      say "XSD Schema Information", :cyan
      say "━" * 60, :cyan
      say ""

      log_verbose "Parsing schema..."
      parser = Parser::XsdParser.new(input_xsd)

      say "File: #{input_xsd}", :green
      say "Size: #{format_file_size(File.size(input_xsd))}"
      say ""

      say "Schema Metadata:", :cyan
      say "  Target Namespace: #{parser.target_namespace || 'None'}"
      say "  Version: #{parser.schema_version || 'Not specified'}"
      say "  Element Form Default: #{parser.element_form_default || 'Not specified'}"
      say ""

      say "Components:", :cyan
      say "  Elements: #{parser.elements.size}"
      say "  Complex Types: #{parser.complex_types.size}"
      say "  Simple Types: #{parser.simple_types.size}"
      say "  Groups: #{parser.groups.size}"
      say "  Attribute Groups: #{parser.attribute_groups.size}"
      say ""

      total_components = parser.elements.size + parser.types.size +
        parser.groups.size + parser.attribute_groups.size
      say "  Total Components: #{total_components}"
      say ""

      # Estimate complexity
      complexity = estimate_complexity(total_components)
      say "Complexity: #{complexity[:level]}", complexity[:color]
      say "  Estimated generation time: #{complexity[:time]}"
      say ""

      if parser.documentation
        say "Schema Documentation:", :cyan
        say "  #{parser.documentation.lines.first.strip}"
        if parser.documentation.lines.size > 1
          say "  (#{parser.documentation.lines.size} lines total)"
        end
      end
    rescue StandardError => e
      error_exit "Error reading schema: #{e.message}"
    end

    no_commands do
      # Validates input file exists and is readable
      def validate_input_file!(path)
        raise ArgumentError, "File not found: #{path}" unless File.exist?(path)

        unless File.readable?(path)
          raise ArgumentError, "File not readable: #{path}"
        end

        raise ArgumentError, "Not a file: #{path}" unless File.file?(path)

        return if path.end_with?(".xsd")

        return unless options[:verbose]

        say "Warning: File does not have .xsd extension",
            :yellow
      end

      # Validates output path is writable
      def validate_output_path!(path)
        dir = File.dirname(path)

        unless Dir.exist?(dir)
          log_verbose "Output directory does not exist, will create: #{dir}"
        end

        return unless File.exist?(path) && !File.writable?(path)

        raise ArgumentError, "Output file exists but is not writable: #{path}"
      end

      # Checks if output file exists and handles --force option
      def check_output_file_exists!(path)
        return unless File.exist?(path)
        return if options[:force]

        say "Warning: Output file already exists: #{path}", :yellow
        return if yes?("Overwrite? (y/n)")

        say "Aborted.", :red
        exit 1
      end

      # Logs message if verbose option is enabled
      def log_verbose(message)
        say "  → #{message}", :cyan if options[:verbose]
      end

      # Executes block with progress indicator for verbose mode
      def log_with_progress(message)
        if options[:verbose]
          say "  → #{message}...", :cyan
          result = yield
          say "    ✓ Complete", :green
          result
        else
          yield
        end
      end

      # Exits with error message
      def error_exit(message, show_backtrace: false)
        say "✗ Error: #{message}", :red

        if show_backtrace && options[:verbose]
          say "\nBacktrace:", :red
          say caller.join("\n"), :red
        end

        exit 1
      end

      # Formats file size for display
      def format_file_size(bytes)
        return "#{bytes} B" if bytes < 1024

        kb = bytes / 1024.0
        return "#{kb.round(1)} KB" if kb < 1024

        mb = kb / 1024.0
        "#{mb.round(2)} MB"
      end

      # Estimates schema complexity
      def estimate_complexity(component_count)
        case component_count
        when 0..10
          { level: "Simple", time: "< 100ms", color: :green }
        when 11..50
          { level: "Moderate", time: "< 500ms", color: :cyan }
        when 51..200
          { level: "Complex", time: "< 2s", color: :yellow }
        else
          { level: "Very Complex", time: "> 2s", color: :red }
        end
      end
    end
  end
end
