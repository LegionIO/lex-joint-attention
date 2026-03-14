# frozen_string_literal: true

require 'legion/extensions/joint_attention/helpers/constants'
require 'legion/extensions/joint_attention/helpers/attention_target'
require 'legion/extensions/joint_attention/helpers/joint_focus_manager'
require 'legion/extensions/joint_attention/runners/joint_attention'

module Legion
  module Extensions
    module JointAttention
      class Client
        include Runners::JointAttention

        def initialize(joint_focus_manager: nil, **)
          @joint_focus_manager = joint_focus_manager || Helpers::JointFocusManager.new
        end

        private

        attr_reader :joint_focus_manager
      end
    end
  end
end
