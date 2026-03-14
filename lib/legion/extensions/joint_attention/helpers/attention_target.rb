# frozen_string_literal: true

module Legion
  module Extensions
    module JointAttention
      module Helpers
        class AttentionTarget
          include Constants

          attr_reader :id, :name, :domain, :priority, :creator_agent_id, :created_at, :attendees, :focus_strength

          def initialize(name:, domain:, priority:, creator_agent_id:)
            @id               = SecureRandom.uuid
            @name             = name
            @domain           = domain
            @priority         = priority.clamp(0.0, 1.0)
            @creator_agent_id = creator_agent_id
            @created_at       = Time.now.utc
            @attendees        = {}
            @focus_strength   = DEFAULT_FOCUS
          end

          def add_attendee(agent_id:, gaze: nil)
            return :at_capacity if @attendees.size >= MAX_ATTENDEES_PER_TARGET
            return :already_attending if @attendees.key?(agent_id)

            @attendees[agent_id] = {
              focus:            DEFAULT_FOCUS,
              gaze:             gaze,
              joined_at:        Time.now.utc,
              mutual_awareness: false
            }
            :joined
          end

          def remove_attendee(agent_id:)
            return :not_found unless @attendees.key?(agent_id)

            @attendees.delete(agent_id)
            :removed
          end

          def update_gaze(agent_id:, gaze:)
            return :not_found unless @attendees.key?(agent_id)

            @attendees[agent_id][:gaze] = gaze
            :updated
          end

          def boost_focus(agent_id:, amount:)
            return :not_found unless @attendees.key?(agent_id)

            current = @attendees[agent_id][:focus]
            @attendees[agent_id][:focus] = [current + amount, 1.0].min
            :boosted
          end

          def establish_mutual_awareness(agent_a:, agent_b:)
            return :not_found unless @attendees.key?(agent_a) && @attendees.key?(agent_b)

            bonus = SHARED_AWARENESS_BONUS
            @attendees[agent_a][:mutual_awareness] = true
            @attendees[agent_b][:mutual_awareness] = true
            @attendees[agent_a][:focus] = [@attendees[agent_a][:focus] + bonus, 1.0].min
            @attendees[agent_b][:focus] = [@attendees[agent_b][:focus] + bonus, 1.0].min
            :established
          end

          def attendee_count
            @attendees.size
          end

          def shared_awareness?
            @attendees.count { |_, v| v[:mutual_awareness] } >= 2
          end

          def focus_label
            FOCUS_LABELS.each { |range, lbl| return lbl if range.cover?(@focus_strength) }
            :fading
          end

          def decay
            @attendees.each_value do |info|
              info[:focus] = [info[:focus] - FOCUS_DECAY, FOCUS_FLOOR].max
            end
            @focus_strength = if @attendees.empty?
                                [@focus_strength - FOCUS_DECAY, FOCUS_FLOOR].max
                              else
                                @attendees.values.sum { |v| v[:focus] } / @attendees.size
                              end
          end

          def faded?
            @focus_strength <= FOCUS_FLOOR && @attendees.empty?
          end

          def prune_faded_attendees
            @attendees.reject! { |_, v| v[:focus] <= FOCUS_FLOOR }
          end

          def to_h
            {
              id:               @id,
              name:             @name,
              domain:           @domain,
              priority:         @priority,
              creator_agent_id: @creator_agent_id,
              created_at:       @created_at,
              focus_strength:   @focus_strength.round(4),
              focus_label:      focus_label,
              attendee_count:   attendee_count,
              shared_awareness: shared_awareness?,
              attendees:        @attendees.transform_values { |v| v.merge(focus: v[:focus].round(4)) }
            }
          end
        end
      end
    end
  end
end
