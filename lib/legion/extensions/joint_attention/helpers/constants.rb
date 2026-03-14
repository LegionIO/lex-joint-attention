# frozen_string_literal: true

module Legion
  module Extensions
    module JointAttention
      module Helpers
        module Constants
          MAX_TARGETS              = 100
          MAX_ATTENDEES_PER_TARGET = 20
          MAX_HISTORY              = 200
          FOCUS_DECAY              = 0.015
          FOCUS_FLOOR              = 0.05
          FOCUS_ALPHA              = 0.12
          DEFAULT_FOCUS            = 0.5
          SHARED_AWARENESS_BONUS   = 0.15
          REFERRAL_BOOST           = 0.2
          MAX_SIMULTANEOUS_TARGETS = 5

          FOCUS_LABELS = {
            (0.8..)     => :locked_on,
            (0.6...0.8) => :focused,
            (0.4...0.6) => :attending,
            (0.2...0.4) => :peripheral,
            (..0.2)     => :fading
          }.freeze
        end
      end
    end
  end
end
