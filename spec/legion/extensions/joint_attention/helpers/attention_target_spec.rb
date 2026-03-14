# frozen_string_literal: true

RSpec.describe Legion::Extensions::JointAttention::Helpers::AttentionTarget do
  subject(:target) do
    described_class.new(name: 'task-planning', domain: :collaboration, priority: 0.7, creator_agent_id: 'agent-1')
  end

  describe '#initialize' do
    it 'assigns fields' do
      expect(target.name).to eq('task-planning')
      expect(target.domain).to eq(:collaboration)
      expect(target.priority).to be_within(0.001).of(0.7)
      expect(target.creator_agent_id).to eq('agent-1')
    end

    it 'assigns a uuid id' do
      expect(target.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'assigns created_at timestamp' do
      expect(target.created_at).to be_a(Time)
    end

    it 'initializes with empty attendees' do
      expect(target.attendees).to be_empty
    end

    it 'clamps priority to 0..1' do
      t = described_class.new(name: 'x', domain: :d, priority: 2.0, creator_agent_id: 'a')
      expect(t.priority).to eq(1.0)

      t2 = described_class.new(name: 'x', domain: :d, priority: -0.5, creator_agent_id: 'a')
      expect(t2.priority).to eq(0.0)
    end

    it 'sets default focus_strength' do
      const = Legion::Extensions::JointAttention::Helpers::Constants::DEFAULT_FOCUS
      expect(target.focus_strength).to eq(const)
    end
  end

  describe '#add_attendee' do
    it 'adds a new attendee and returns :joined' do
      result = target.add_attendee(agent_id: 'agent-2')
      expect(result).to eq(:joined)
      expect(target.attendees).to have_key('agent-2')
    end

    it 'returns :already_attending when agent is already present' do
      target.add_attendee(agent_id: 'agent-2')
      result = target.add_attendee(agent_id: 'agent-2')
      expect(result).to eq(:already_attending)
    end

    it 'stores gaze direction when provided' do
      target.add_attendee(agent_id: 'agent-2', gaze: :risk_assessment)
      expect(target.attendees['agent-2'][:gaze]).to eq(:risk_assessment)
    end

    it 'sets mutual_awareness to false by default' do
      target.add_attendee(agent_id: 'agent-2')
      expect(target.attendees['agent-2'][:mutual_awareness]).to be false
    end

    it 'returns :at_capacity when MAX_ATTENDEES_PER_TARGET is reached' do
      max = Legion::Extensions::JointAttention::Helpers::Constants::MAX_ATTENDEES_PER_TARGET
      max.times { |i| target.add_attendee(agent_id: "agent-#{i + 100}") }
      result = target.add_attendee(agent_id: 'overflow-agent')
      expect(result).to eq(:at_capacity)
    end
  end

  describe '#remove_attendee' do
    before { target.add_attendee(agent_id: 'agent-2') }

    it 'removes attendee and returns :removed' do
      result = target.remove_attendee(agent_id: 'agent-2')
      expect(result).to eq(:removed)
      expect(target.attendees).not_to have_key('agent-2')
    end

    it 'returns :not_found for unknown agent' do
      expect(target.remove_attendee(agent_id: 'unknown')).to eq(:not_found)
    end
  end

  describe '#update_gaze' do
    before { target.add_attendee(agent_id: 'agent-2') }

    it 'updates gaze and returns :updated' do
      result = target.update_gaze(agent_id: 'agent-2', gaze: :timeline)
      expect(result).to eq(:updated)
      expect(target.attendees['agent-2'][:gaze]).to eq(:timeline)
    end

    it 'returns :not_found for unknown agent' do
      expect(target.update_gaze(agent_id: 'ghost', gaze: :something)).to eq(:not_found)
    end
  end

  describe '#boost_focus' do
    before { target.add_attendee(agent_id: 'agent-2') }

    it 'increases focus for the agent' do
      before_val = target.attendees['agent-2'][:focus]
      target.boost_focus(agent_id: 'agent-2', amount: 0.2)
      expect(target.attendees['agent-2'][:focus]).to be > before_val
    end

    it 'caps focus at 1.0' do
      target.boost_focus(agent_id: 'agent-2', amount: 5.0)
      expect(target.attendees['agent-2'][:focus]).to eq(1.0)
    end

    it 'returns :not_found for unknown agent' do
      expect(target.boost_focus(agent_id: 'ghost', amount: 0.1)).to eq(:not_found)
    end
  end

  describe '#establish_mutual_awareness' do
    before do
      target.add_attendee(agent_id: 'agent-1')
      target.add_attendee(agent_id: 'agent-2')
    end

    it 'sets mutual_awareness for both agents and returns :established' do
      result = target.establish_mutual_awareness(agent_a: 'agent-1', agent_b: 'agent-2')
      expect(result).to eq(:established)
      expect(target.attendees['agent-1'][:mutual_awareness]).to be true
      expect(target.attendees['agent-2'][:mutual_awareness]).to be true
    end

    it 'boosts focus for both agents' do
      before_a = target.attendees['agent-1'][:focus]
      before_b = target.attendees['agent-2'][:focus]
      target.establish_mutual_awareness(agent_a: 'agent-1', agent_b: 'agent-2')
      expect(target.attendees['agent-1'][:focus]).to be > before_a
      expect(target.attendees['agent-2'][:focus]).to be > before_b
    end

    it 'returns :not_found when one agent is missing' do
      result = target.establish_mutual_awareness(agent_a: 'agent-1', agent_b: 'ghost')
      expect(result).to eq(:not_found)
    end
  end

  describe '#attendee_count' do
    it 'returns 0 initially' do
      expect(target.attendee_count).to eq(0)
    end

    it 'increments when attendees join' do
      target.add_attendee(agent_id: 'agent-2')
      target.add_attendee(agent_id: 'agent-3')
      expect(target.attendee_count).to eq(2)
    end
  end

  describe '#shared_awareness?' do
    it 'returns false with no mutual awareness' do
      target.add_attendee(agent_id: 'agent-2')
      expect(target.shared_awareness?).to be false
    end

    it 'returns true when two or more agents have mutual awareness' do
      target.add_attendee(agent_id: 'agent-1')
      target.add_attendee(agent_id: 'agent-2')
      target.establish_mutual_awareness(agent_a: 'agent-1', agent_b: 'agent-2')
      expect(target.shared_awareness?).to be true
    end
  end

  describe '#decay' do
    before { target.add_attendee(agent_id: 'agent-2') }

    it 'reduces attendee focus' do
      before_val = target.attendees['agent-2'][:focus]
      target.decay
      expect(target.attendees['agent-2'][:focus]).to be < before_val
    end

    it 'does not drop focus below FOCUS_FLOOR' do
      floor = Legion::Extensions::JointAttention::Helpers::Constants::FOCUS_FLOOR
      200.times { target.decay }
      expect(target.attendees['agent-2'][:focus]).to be >= floor
    end

    it 'updates overall focus_strength based on attendees' do
      original = target.focus_strength
      200.times { target.decay }
      expect(target.focus_strength).to be <= original
    end
  end

  describe '#faded?' do
    it 'returns false when focus is above floor or attendees present' do
      expect(target.faded?).to be false
    end

    it 'returns true when focus is at floor and no attendees' do
      200.times { target.decay }
      expect(target.faded?).to be true
    end
  end

  describe '#prune_faded_attendees' do
    it 'removes attendees whose focus is at or below FOCUS_FLOOR' do
      target.add_attendee(agent_id: 'fading')
      target.attendees['fading'][:focus] = Legion::Extensions::JointAttention::Helpers::Constants::FOCUS_FLOOR
      target.prune_faded_attendees
      expect(target.attendees).not_to have_key('fading')
    end

    it 'keeps attendees above floor' do
      target.add_attendee(agent_id: 'active')
      target.prune_faded_attendees
      expect(target.attendees).to have_key('active')
    end
  end

  describe '#focus_label' do
    it 'returns :locked_on for high focus' do
      target.instance_variable_set(:@focus_strength, 0.9)
      expect(target.focus_label).to eq(:locked_on)
    end

    it 'returns :focused for 0.6..0.8 range' do
      target.instance_variable_set(:@focus_strength, 0.7)
      expect(target.focus_label).to eq(:focused)
    end

    it 'returns :attending for 0.4..0.6 range' do
      target.instance_variable_set(:@focus_strength, 0.5)
      expect(target.focus_label).to eq(:attending)
    end

    it 'returns :fading for very low focus' do
      target.instance_variable_set(:@focus_strength, 0.1)
      expect(target.focus_label).to eq(:fading)
    end
  end

  describe '#to_h' do
    it 'returns a hash with all required fields' do
      h = target.to_h
      expect(h).to include(
        :id, :name, :domain, :priority, :creator_agent_id,
        :created_at, :focus_strength, :focus_label,
        :attendee_count, :shared_awareness, :attendees
      )
    end

    it 'rounds focus_strength to 4 decimal places' do
      target.instance_variable_set(:@focus_strength, 0.123456789)
      expect(target.to_h[:focus_strength]).to eq(0.1235)
    end
  end
end
