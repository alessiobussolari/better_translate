# frozen_string_literal: true

module BetterTranslate
  # Utility classes and helpers
  #
  # Contains various utility classes used throughout BetterTranslate.
  module Utils
    # Utilities for flattening and unflattening nested hashes
    #
    # Used to convert nested YAML structures to flat key-value pairs
    # and back again.
    #
    # @example Flatten nested hash
    #   nested = { "user" => { "name" => "John", "age" => 30 } }
    #   flat = HashFlattener.flatten(nested)
    #   #=> { "user.name" => "John", "user.age" => 30 }
    #
    # @example Unflatten to nested hash
    #   flat = { "user.name" => "John", "user.age" => 30 }
    #   HashFlattener.unflatten(flat)
    #   #=> { "user" => { "name" => "John", "age" => 30 } }
    #
    class HashFlattener
      # Flatten a nested hash to dot-notation keys
      #
      # Recursively converts nested hashes into a single-level hash
      # with keys joined by a separator (default: ".").
      #
      # @param hash [Hash] Nested hash to flatten
      # @param parent_key [String] Parent key prefix (used internally for recursion)
      # @param separator [String] Key separator (default: ".")
      # @return [Hash] Flattened hash
      #
      # @example Basic flattening
      #   nested = {
      #     "config" => {
      #       "database" => {
      #         "host" => "localhost"
      #       }
      #     }
      #   }
      #   HashFlattener.flatten(nested)
      #   #=> { "config.database.host" => "localhost" }
      #
      # @example Custom separator
      #   HashFlattener.flatten(nested, "", "/")
      #   #=> { "config/database/host" => "localhost" }
      #
      def self.flatten(hash, parent_key = "", separator = ".")
        # @type var result: Hash[String, untyped]
        hash.each_with_object({}) do |(key, value), result|
          new_key = parent_key.empty? ? key.to_s : "#{parent_key}#{separator}#{key}"

          if value.is_a?(Hash)
            result.merge!(flatten(value, new_key, separator))
          else
            result[new_key] = value
          end
        end
      end

      # Unflatten a hash with dot-notation keys to nested structure
      #
      # Converts a flat hash with delimited keys back into a nested
      # hash structure.
      #
      # @param hash [Hash] Flattened hash
      # @param separator [String] Key separator (default: ".")
      # @return [Hash] Nested hash
      #
      # @example Basic unflattening
      #   flat = { "config.database.host" => "localhost" }
      #   HashFlattener.unflatten(flat)
      #   #=> {
      #   #     "config" => {
      #   #       "database" => {
      #   #         "host" => "localhost"
      #   #       }
      #   #     }
      #   #   }
      #
      # @example Custom separator
      #   flat = { "config/database/host" => "localhost" }
      #   HashFlattener.unflatten(flat, "/")
      #   #=> { "config" => { "database" => { "host" => "localhost" } } }
      #
      def self.unflatten(hash, separator = ".")
        # @type var result: Hash[String, untyped]
        hash.each_with_object({}) do |(key, value), result|
          keys = key.split(separator)
          last_key = keys.pop

          # Build nested structure
          nested = keys.reduce(result) do |memo, k|
            memo[k] ||= {}
            memo[k]
          end

          nested[last_key] = value if last_key
        end
      end
    end
  end
end
