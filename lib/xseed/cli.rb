# frozen_string_literal: true

require "thor"
require "fileutils"
require_relative "svg/svg_generator"
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

      The diagram shows elements, types, attributes, and their relationships in a
      hierarchical tree layout.

      Single-Element Mode:
        Use --element to generate a diagram for a single element instead of the entire schema.
        Use --all-elements to generate separate diagrams for all elements in the schema.
        Use --output-dir to specify a directory for batch output (required with --all-elements).

      Examples:

        # Generate SVG and write to file
        $ xseed svg schema.xsd -o diagram.svg

        # Generate diagram for a single element
        $ xseed svg schema.xsd -e Order -o order.svg

        # Generate diagrams for all elements
        $ xseed svg schema.xsd --all-elements -d output_dir

        # Output SVG to stdout
        $ xseed svg schema.xsd

        # Verbose output with progress
        $ xseed svg large-schema.xsd -o output.svg --verbose

      For more information, visit: https://github.com/metanorma/xseed
    DESC
    option :output,
           aliases: "-o",
           desc: "Output file path (default: stdout)",
           banner: "PATH"
    option :element,
           aliases: "-e",
           desc: "Generate diagram for a single element",
           banner: "ELEMENT_NAME"
    option :all_elements,
           type: :boolean,
           desc: "Generate diagrams for all elements in schema"
    option :output_dir,
           aliases: "-d",
           desc: "Output directory for batch generation (required with --all-elements)",
           banner: "DIR"
    option :force,
           type: :boolean,
           aliases: "-f",
           desc: "Overwrite output file if it exists"
    def svg(input_xsd)
      start_time = Time.now

      # Validate input file
      validate_input_file!(input_xsd)

      # Handle --all-elements mode
      if options[:all_elements]
        unless options[:output_dir]
          error_exit "--output-dir/-d is required when using --all-elements"
        end

        generate_all_elements(input_xsd)
        return
      end

      # Handle single element mode
      if options[:element]
        generate_single_element(input_xsd, options[:element])
        return
      end

      # Standard schema-wide generation
      # Check output file permissions if specified
      validate_output_path!(options[:output]) if options[:output]

      # Create generator with progress tracking
      log_verbose "Parsing XSD schema: #{input_xsd}"
      generator = create_generator(input_xsd)
      log_verbose "Parser initialized successfully"

      # Determine output path
      output_path = options[:output]

      if output_path
        # Check if output file exists
        check_output_file_exists!(output_path)

        # Generate and write to file with progress
        log_with_progress("Generating SVG diagram") do
          generator.generate_file(output_path)
        end

        elapsed = Time.now - start_time
        say "✓ SVG diagram generated: #{output_path}", :green
        log_verbose "Generation completed in #{elapsed.round(3)}s"
      else
        # Generate and output to stdout
        log_verbose "Generating SVG to stdout"
        svg_content = generator.generate
        say svg_content
      end
    rescue ArgumentError => e
      error_exit "Validation error: #{e.message}"
    rescue ParserError => e
      error_exit "Parser error: #{e.message}"
    rescue Svg::GenerationError => e
      error_exit "SVG generation error: #{e.message}"
    rescue Errno::EACCES => e
      error_exit "Permission denied: #{e.message}"
    rescue Errno::ENOSPC
      error_exit "No space left on device"
    rescue StandardError => e
      error_exit "Unexpected error: #{e.message}", show_backtrace: true
    end

    desc "html INPUT_XSD [OPTIONS]",
         "Generate HTML documentation from XSD"
    long_desc <<~DESC
      Generate comprehensive HTML documentation from an XSD schema file.

      Phase 2, Weeks 1-2: Foundation Layer is now available with basic HTML generation.
      Full documentation features will be available in Weeks 3-6.

      Options:
        -o, --output PATH    Output HTML file path
        -t, --title TEXT     Documentation title
        --css PATH           External CSS file to include
        --include-svg        Include SVG diagrams (default: true)

      Example:
        $ xseed html schema.xsd -o documentation.html -t "My Schema"

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
    option :include_svg,
           type: :boolean,
           default: true,
           desc: "Include SVG diagrams"
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
        say ""
        say "Note: Phase 2 Foundation Layer (Weeks 1-2) is active.", :yellow
        say "Full documentation features coming in Weeks 3-6.", :yellow
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
      say "Xseed - XSD Schema Documentation Generator", :cyan
      say "━" * 60, :cyan
      say ""
      say "Version: #{Xseed::VERSION}", :green
      say "Phase: 1 (SVG Generation)", :green
      say ""
      say "Features:"
      say "  ✓ SVG diagram generation", :green
      say "  ✓ XSD schema parsing", :green
      say "  ✓ Symbol tree visualization", :green
      say "  ⧗ HTML documentation (Phase 2)", :yellow
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

      # Creates SVG generator with error handling
      def create_generator(input_xsd, element: nil)
        Svg::SvgGenerator.new(input_xsd, element: element)
      rescue StandardError => e
        raise ParserError, "Failed to initialize parser: #{e.message}"
      end

      # Generates diagram for a single element
      def generate_single_element(input_xsd, element_name)
        start_time = Time.now

        log_verbose "Generating diagram for element: #{element_name}"
        generator = create_generator(input_xsd, element: element_name)

        output_path = options[:output]

        if output_path
          validate_output_path!(output_path)
          check_output_file_exists!(output_path)

          log_with_progress("Generating SVG for element '#{element_name}'") do
            generator.generate_file(output_path)
          end

          elapsed = Time.now - start_time
          say "✓ SVG diagram generated for '#{element_name}': #{output_path}", :green
          log_verbose "Generation completed in #{elapsed.round(3)}s"
        else
          log_verbose "Generating SVG for element '#{element_name}' to stdout"
          svg_content = generator.generate
          say svg_content
        end
      rescue ArgumentError => e
        error_exit "Element error: #{e.message}"
      end

      # Generates diagrams for all elements in schema
      def generate_all_elements(input_xsd)
        start_time = Time.now
        output_dir = options[:output_dir]

        # Create output directory
        FileUtils.mkdir_p(output_dir)
        log_verbose "Created output directory: #{output_dir}"

        # Get all element names
        log_verbose "Scanning schema for elements..."
        generator = create_generator(input_xsd)
        element_names = generator.all_element_names

        if element_names.empty?
          error_exit "No elements found in schema"
        end

        say "Found #{element_names.length} elements in schema", :cyan
        say ""

        # Generate diagram for each element
        success_count = 0
        error_count = 0

        element_names.each_with_index do |element_name, index|
          begin
            output_file = File.join(output_dir, "#{element_name}.svg")

            if options[:verbose]
              say "  [#{index + 1}/#{element_names.length}] Generating #{element_name}...", :cyan
            else
              # Show progress bar for non-verbose mode
              print "\r  Progress: [#{index + 1}/#{element_names.length}] #{element_name}".ljust(60)
            end

            element_generator = create_generator(input_xsd, element: element_name)
            element_generator.generate_file(output_file)

            success_count += 1
            log_verbose "    ✓ Written to #{output_file}"
          rescue StandardError => e
            error_count += 1
            say "\n  ✗ Error generating #{element_name}: #{e.message}", :red if options[:verbose]
          end
        end

        # Clear progress line and show summary
        print "\r".ljust(80) + "\r" unless options[:verbose]
        say ""

        elapsed = Time.now - start_time
        say "✓ Batch generation complete", :green
        say "  Successfully generated: #{success_count}/#{element_names.length} diagrams", :green
        say "  Errors: #{error_count}", :red if error_count > 0
        say "  Output directory: #{output_dir}", :cyan
        log_verbose "  Total time: #{elapsed.round(3)}s"
        log_verbose "  Average time per element: #{(elapsed / element_names.length).round(3)}s"
      rescue StandardError => e
        error_exit "Batch generation error: #{e.message}", show_backtrace: true
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
