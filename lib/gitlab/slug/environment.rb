# frozen_string_literal: true

# An environment name is not necessarily suitable for use in URLs, DNS
# or other third-party contexts, so provide a slugified version. A slug has
# the following properties:
#   * contains only lowercase letters (a-z), numbers (0-9), and '-'
#   * begins with a letter
#   * has a maximum length of 24 bytes (OpenShift limitation)
#   * cannot end with `-`
module Gitlab
  module Slug
    class Environment
      attr_reader :name

      LETTERS = ('a'..'z').freeze
      NUMBERS = ('0'..'9').freeze
      SUFFIX_CHARS = LETTERS.to_a + NUMBERS.to_a

      def initialize(name)
        @name = name
      end

      def generate
        # Lowercase letters and numbers only
        slugified = name.to_s.downcase.gsub(/[^a-z0-9]/, '-')

        # Must start with a letter
        slugified = 'env-' + slugified unless slugified.match?(/^[a-z]/)

        # Repeated dashes are invalid (OpenShift limitation)
        slugified.squeeze!('-')

        slugified = slugified[0..16]
        slugified << '-' unless slugified.end_with?('-')
        slugified << random_suffix

        slugified
      end

      private

      # Slugifying a name may remove the uniqueness guarantee afforded by it being
      # based on name (which must be unique).
      # Also when environment is renamed slug isn't being changed, which can lead to collisions.
      # To compensate, we add a random 6-byte suffix. This is not *guaranteed* uniqueness,
      # but the chance of collisions is vanishingly small
      def random_suffix
        (0..5).map { SUFFIX_CHARS.sample }.join
      end
    end
  end
end
