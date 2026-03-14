# frozen_string_literal: true

require 'legion/extensions/actors/every'

module Legion
  module Extensions
    module JointAttention
      module Actor
        class Decay < Legion::Extensions::Actors::Every
          def runner_class
            Legion::Extensions::JointAttention::Runners::JointAttention
          end

          def runner_function
            'update_joint_attention'
          end

          def time
            120
          end

          def run_now?
            false
          end

          def use_runner?
            false
          end

          def check_subtask?
            false
          end

          def generate_task?
            false
          end
        end
      end
    end
  end
end
