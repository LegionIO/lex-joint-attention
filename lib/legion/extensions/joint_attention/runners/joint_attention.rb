# frozen_string_literal: true

module Legion
  module Extensions
    module JointAttention
      module Runners
        module JointAttention
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def create_attention_target(name:, domain:, creator:, priority: 0.5, **)
            target = joint_focus_manager.create_target(name: name, domain: domain, priority: priority, creator: creator)
            Legion::Logging.debug "[joint_attention] create_target: name=#{name} domain=#{domain} priority=#{priority} " \
                                  "creator=#{creator} id=#{target.id}"
            { success: true, target: target.to_h }
          end

          def join_attention(target_id:, agent_id:, gaze: nil, **)
            result = joint_focus_manager.join_target(target_id: target_id, agent_id: agent_id, gaze: gaze)
            Legion::Logging.debug "[joint_attention] join: target_id=#{target_id} agent_id=#{agent_id} gaze=#{gaze} result=#{result}"
            { success: %i[joined already_attending].include?(result), result: result, target_id: target_id, agent_id: agent_id }
          end

          def leave_attention(target_id:, agent_id:, **)
            result = joint_focus_manager.leave_target(target_id: target_id, agent_id: agent_id)
            Legion::Logging.debug "[joint_attention] leave: target_id=#{target_id} agent_id=#{agent_id} result=#{result}"
            { success: result == :removed, result: result, target_id: target_id, agent_id: agent_id }
          end

          def direct_attention(from_agent:, to_agent:, target_id:, **)
            result = joint_focus_manager.direct_attention(from_agent: from_agent, to_agent: to_agent, target_id: target_id)
            Legion::Logging.debug "[joint_attention] direct: from=#{from_agent} to=#{to_agent} target_id=#{target_id} result=#{result}"
            { success: %i[directed already_attending].include?(result), result: result, target_id: target_id,
              from_agent: from_agent, to_agent: to_agent }
          end

          def establish_mutual_awareness(target_id:, agent_a:, agent_b:, **)
            result = joint_focus_manager.establish_shared(target_id: target_id, agent_a: agent_a, agent_b: agent_b)
            Legion::Logging.debug "[joint_attention] mutual_awareness: target_id=#{target_id} " \
                                  "agent_a=#{agent_a} agent_b=#{agent_b} result=#{result}"
            { success: result == :established, result: result, target_id: target_id, agent_a: agent_a, agent_b: agent_b }
          end

          def update_gaze(target_id:, agent_id:, gaze:, **)
            result = joint_focus_manager.update_gaze(target_id: target_id, agent_id: agent_id, gaze: gaze)
            Legion::Logging.debug "[joint_attention] update_gaze: target_id=#{target_id} agent_id=#{agent_id} gaze=#{gaze} result=#{result}"
            { success: result == :updated, result: result, target_id: target_id, agent_id: agent_id, gaze: gaze }
          end

          def shared_focus(agent_a:, agent_b:, **)
            targets = joint_focus_manager.shared_targets(agent_a: agent_a, agent_b: agent_b)
            Legion::Logging.debug "[joint_attention] shared_focus: agent_a=#{agent_a} agent_b=#{agent_b} count=#{targets.size}"
            { success: true, agent_a: agent_a, agent_b: agent_b, shared_targets: targets.map(&:to_h), count: targets.size }
          end

          def attention_targets_for(agent_id:, **)
            targets = joint_focus_manager.targets_for_agent(agent_id: agent_id)
            Legion::Logging.debug "[joint_attention] targets_for: agent_id=#{agent_id} count=#{targets.size}"
            { success: true, agent_id: agent_id, targets: targets.map(&:to_h), count: targets.size }
          end

          def update_joint_attention(**)
            joint_focus_manager.decay_all
            stats = joint_focus_manager.to_h
            Legion::Logging.debug "[joint_attention] decay_tick: targets=#{stats[:target_count]} agents=#{stats[:agent_count]}"
            { success: true, targets: stats[:target_count], agents: stats[:agent_count], history: stats[:history_size] }
          end

          def joint_attention_stats(**)
            stats = joint_focus_manager.to_h
            Legion::Logging.debug "[joint_attention] stats: targets=#{stats[:target_count]} agents=#{stats[:agent_count]}"
            { success: true, stats: stats }
          end

          private

          def joint_focus_manager
            @joint_focus_manager ||= Helpers::JointFocusManager.new
          end
        end
      end
    end
  end
end
