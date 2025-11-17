# frozen_string_literal: true

module Xseed
  module Svg
    module Simplification
      # Configuration for SVG simplification modes and thresholds
      # Auto-detects appropriate mode based on schema complexity
      class SimplificationConfig
        # Simplification modes
        MODES = {
          full: {
            enabled: false,
            max_depth: Float::INFINITY,
            reuse_threshold: Float::INFINITY,
            description: "Full expansion (no simplification)"
          },
          balanced: {
            enabled: true,
            max_depth: 6,
            reuse_threshold: 3,
            description: "Balanced mode (moderate simplification)"
          },
          compact: {
            enabled: true,
            max_depth: 4,
            reuse_threshold: 2,
            description: "Compact mode (aggressive simplification)"
          }
        }.freeze

        # Schema size thresholds for mode auto-detection
        THRESHOLDS = {
          compact: 500,   # > 500 elements = compact mode
          balanced: 200,  # 200-500 elements = balanced mode
          full: 0         # < 200 elements = full mode
        }.freeze

        attr_reader :mode, :max_depth, :reuse_threshold, :enabled

        def initialize(mode: nil, schema_size: nil)
          if mode
            @mode = validate_mode(mode)
          elsif schema_size
            @mode = detect_mode(schema_size)
          else
            @mode = :balanced
          end

          apply_mode_settings
        end

        def enabled?
          @enabled
        end

        def should_limit_depth?(depth)
          enabled? && depth >= @max_depth
        end

        def should_simplify_pattern?(usage_count)
          enabled? && usage_count >= @reuse_threshold
        end

        def description
          MODES[@mode][:description]
        end

        def self.modes
          MODES
        end

        private

        def validate_mode(mode)
          mode = mode.to_sym if mode.is_a?(String)
          unless MODES.key?(mode)
            raise ArgumentError,
                  "Invalid mode: #{mode}. Must be one of #{MODES.keys.join(', ')}"
          end
          mode
        end

        def detect_mode(size)
          return :compact if size > THRESHOLDS[:compact]
          return :balanced if size > THRESHOLDS[:balanced]

          :full
        end

        def apply_mode_settings
          settings = MODES[@mode]
          @enabled = settings[:enabled]
          @max_depth = settings[:max_depth]
          @reuse_threshold = settings[:reuse_threshold]
        end
      end
    end
  end
end
