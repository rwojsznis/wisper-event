# frozen_string_literal: true

require 'wisper'
require_relative 'wisper_event/version'

module WisperEvent
  class << self
    def apply!
      require_relative 'wisper/listener'
      require_relative 'wisper_event/patches'
    end
  end
end
