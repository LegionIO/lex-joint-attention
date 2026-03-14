# frozen_string_literal: true

module Legion
  module Extensions
    module JointAttention
      module Helpers
        class JointFocusManager
          include Constants

          attr_reader :targets, :history

          def initialize
            @targets     = {}
            @agent_focus = {}
            @history     = []
          end

          def create_target(name:, domain:, priority:, creator:)
            prune_targets if @targets.size >= MAX_TARGETS
            target = AttentionTarget.new(
              name:             name,
              domain:           domain,
              priority:         priority,
              creator_agent_id: creator
            )
            @targets[target.id] = target
            record_history(event: :target_created, target_id: target.id, agent_id: creator)
            join_target(target_id: target.id, agent_id: creator)
            target
          end

          def join_target(target_id:, agent_id:, gaze: nil)
            target = @targets[target_id]
            return :target_not_found unless target

            current = agent_target_ids(agent_id)
            return :capacity_exceeded if current.size >= MAX_SIMULTANEOUS_TARGETS && !current.include?(target_id)

            result = target.add_attendee(agent_id: agent_id, gaze: gaze)
            if result == :joined
              @agent_focus[agent_id] ||= []
              @agent_focus[agent_id] << target_id unless @agent_focus[agent_id].include?(target_id)
              record_history(event: :agent_joined, target_id: target_id, agent_id: agent_id)
            end
            result
          end

          def leave_target(target_id:, agent_id:)
            target = @targets[target_id]
            return :target_not_found unless target

            result = target.remove_attendee(agent_id: agent_id)
            if result == :removed
              @agent_focus[agent_id]&.delete(target_id)
              record_history(event: :agent_left, target_id: target_id, agent_id: agent_id)
            end
            result
          end

          def direct_attention(from_agent:, to_agent:, target_id:)
            target = @targets[target_id]
            return :target_not_found unless target

            return :referrer_not_attending unless target.attendees.key?(from_agent)

            join_result = join_target(target_id: target_id, agent_id: to_agent)
            return join_result if join_result == :capacity_exceeded

            target.boost_focus(agent_id: to_agent, amount: REFERRAL_BOOST) if target.attendees.key?(to_agent)
            record_history(event: :attention_directed, target_id: target_id, from_agent: from_agent, to_agent: to_agent)
            :directed
          end

          def establish_shared(target_id:, agent_a:, agent_b:)
            target = @targets[target_id]
            return :target_not_found unless target

            result = target.establish_mutual_awareness(agent_a: agent_a, agent_b: agent_b)
            record_history(event: :shared_awareness, target_id: target_id, agent_a: agent_a, agent_b: agent_b) if result == :established
            result
          end

          def update_gaze(target_id:, agent_id:, gaze:)
            target = @targets[target_id]
            return :target_not_found unless target

            target.update_gaze(agent_id: agent_id, gaze: gaze)
          end

          def targets_for_agent(agent_id:)
            ids = agent_target_ids(agent_id)
            ids.filter_map { |tid| @targets[tid] }
          end

          def attendees_for_target(target_id:)
            target = @targets[target_id]
            return [] unless target

            target.attendees.keys
          end

          def shared_targets(agent_a:, agent_b:)
            ids_a = agent_target_ids(agent_a)
            ids_b = agent_target_ids(agent_b)
            (ids_a & ids_b).filter_map { |tid| @targets[tid] }
          end

          def decay_all
            @targets.each_value(&:decay)
            @targets.each_value(&:prune_faded_attendees)
            sync_agent_focus
            @targets.reject! { |_, t| t.faded? }
          end

          def target_count
            @targets.size
          end

          def to_h
            {
              target_count: target_count,
              agent_count:  @agent_focus.count { |_, ids| ids.any? },
              history_size: @history.size,
              targets:      @targets.transform_values(&:to_h)
            }
          end

          private

          def agent_target_ids(agent_id)
            @agent_focus.fetch(agent_id, [])
          end

          def sync_agent_focus
            @agent_focus.each_value { |ids| ids.select! { |tid| @targets.key?(tid) } }
          end

          def record_history(event)
            @history << event.merge(at: Time.now.utc)
            @history.shift while @history.size > MAX_HISTORY
          end

          def prune_targets
            sorted = @targets.values.sort_by { |t| [t.focus_strength, t.created_at] }
            to_remove = sorted.first(@targets.size - MAX_TARGETS + 1)
            to_remove.each { |t| @targets.delete(t.id) }
            sync_agent_focus
          end
        end
      end
    end
  end
end
