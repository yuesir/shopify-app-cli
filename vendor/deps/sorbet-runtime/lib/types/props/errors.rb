# frozen_string_literal: true
# typed: strong

module T::Props
  class Error < StandardError; end
  class InvalidValueError < Error; end
  class ImmutableProp < Error; end
end
