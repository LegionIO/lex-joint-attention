# frozen_string_literal: true

require 'securerandom'
require 'legion/extensions/joint_attention/version'
require 'legion/extensions/joint_attention/helpers/constants'
require 'legion/extensions/joint_attention/helpers/attention_target'
require 'legion/extensions/joint_attention/helpers/joint_focus_manager'
require 'legion/extensions/joint_attention/runners/joint_attention'
require 'legion/extensions/joint_attention/client'

module Legion
  module Extensions
    module JointAttention
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
