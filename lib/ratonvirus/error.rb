# frozen_string_literal: true

module Ratonvirus
  class Error < StandardError; end

  class InvalidError < Error; end

  class NotDefinedError < Error; end

  class NotImplementedError < Error; end
end
