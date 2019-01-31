# frozen_string_literal: true

module Bot
  module Errors
    class CommonError < StandardError; end

    class NotFound < CommonError; end
    class MissingAttribute < CommonError; end

    class ScrollLoop < CommonError; end
  end
end
