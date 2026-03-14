# frozen_string_literal: true

RSpec.describe Legion::Extensions::JointAttention::Helpers::JointFocusManager do
  subject(:manager) { described_class.new }

  let!(:target) do
    manager.create_target(name: 'task-alpha', domain: :planning, priority: 0.8, creator: 'agent-1')
  end

  describe '#create_target' do
    it 'creates a target and returns an AttentionTarget' do
      expect(target).to be_a(Legion::Extensions::JointAttention::Helpers::AttentionTarget)
      expect(target.name).to eq('task-alpha')
    end

    it 'adds the target to @targets' do
      expect(manager.targets).to have_key(target.id)
    end

    it 'auto-joins the creator' do
      expect(target.attendees).to have_key('agent-1')
    end

    it 'records history' do
      expect(manager.history).not_to be_empty
      expect(manager.history.last[:event]).to eq(:agent_joined)
    end

    it 'increments target_count' do
      expect(manager.target_count).to eq(1)
    end
  end

  describe '#join_target' do
    it 'adds a second agent to the target' do
      result = manager.join_target(target_id: target.id, agent_id: 'agent-2')
      expect(result).to eq(:joined)
      expect(target.attendees).to have_key('agent-2')
    end

    it 'returns :target_not_found for unknown target' do
      result = manager.join_target(target_id: 'bogus', agent_id: 'agent-2')
      expect(result).to eq(:target_not_found)
    end

    it 'returns :already_attending when agent already there' do
      manager.join_target(target_id: target.id, agent_id: 'agent-2')
      result = manager.join_target(target_id: target.id, agent_id: 'agent-2')
      expect(result).to eq(:already_attending)
    end

    it 'enforces MAX_SIMULTANEOUS_TARGETS per agent' do
      max = Legion::Extensions::JointAttention::Helpers::Constants::MAX_SIMULTANEOUS_TARGETS
      max.times do |i|
        t = manager.create_target(name: "agent-x-target-#{i}", domain: :d, priority: 0.5, creator: 'other')
        manager.join_target(target_id: t.id, agent_id: 'agent-x')
      end
      extra = manager.create_target(name: 'overflow', domain: :d, priority: 0.5, creator: 'other2')
      result = manager.join_target(target_id: extra.id, agent_id: 'agent-x')
      expect(result).to eq(:capacity_exceeded)
    end

    it 'records join history' do
      manager.join_target(target_id: target.id, agent_id: 'agent-3')
      events = manager.history.map { |h| h[:event] }
      expect(events).to include(:agent_joined)
    end
  end

  describe '#leave_target' do
    before { manager.join_target(target_id: target.id, agent_id: 'agent-2') }

    it 'removes the agent and returns :removed' do
      result = manager.leave_target(target_id: target.id, agent_id: 'agent-2')
      expect(result).to eq(:removed)
      expect(target.attendees).not_to have_key('agent-2')
    end

    it 'returns :target_not_found for unknown target' do
      result = manager.leave_target(target_id: 'bogus', agent_id: 'agent-2')
      expect(result).to eq(:target_not_found)
    end

    it 'returns :not_found when agent not attending' do
      result = manager.leave_target(target_id: target.id, agent_id: 'never-joined')
      expect(result).to eq(:not_found)
    end

    it 'records leave history' do
      manager.leave_target(target_id: target.id, agent_id: 'agent-2')
      events = manager.history.map { |h| h[:event] }
      expect(events).to include(:agent_left)
    end
  end

  describe '#direct_attention' do
    before { manager.join_target(target_id: target.id, agent_id: 'agent-1') }

    it 'joins recipient to target and returns :directed' do
      result = manager.direct_attention(from_agent: 'agent-1', to_agent: 'agent-2', target_id: target.id)
      expect(result).to eq(:directed)
      expect(target.attendees).to have_key('agent-2')
    end

    it 'returns :target_not_found for unknown target' do
      result = manager.direct_attention(from_agent: 'agent-1', to_agent: 'agent-2', target_id: 'bogus')
      expect(result).to eq(:target_not_found)
    end

    it 'returns :referrer_not_attending when from_agent is not on target' do
      result = manager.direct_attention(from_agent: 'nobody', to_agent: 'agent-2', target_id: target.id)
      expect(result).to eq(:referrer_not_attending)
    end

    it 'boosts focus of recipient' do
      manager.direct_attention(from_agent: 'agent-1', to_agent: 'agent-2', target_id: target.id)
      const = Legion::Extensions::JointAttention::Helpers::Constants
      expected_min = const::DEFAULT_FOCUS + const::REFERRAL_BOOST
      expect(target.attendees['agent-2'][:focus]).to be >= expected_min
    end

    it 'records direction history' do
      manager.direct_attention(from_agent: 'agent-1', to_agent: 'agent-2', target_id: target.id)
      events = manager.history.map { |h| h[:event] }
      expect(events).to include(:attention_directed)
    end
  end

  describe '#establish_shared' do
    before do
      manager.join_target(target_id: target.id, agent_id: 'agent-1')
      manager.join_target(target_id: target.id, agent_id: 'agent-2')
    end

    it 'establishes mutual awareness and returns :established' do
      result = manager.establish_shared(target_id: target.id, agent_a: 'agent-1', agent_b: 'agent-2')
      expect(result).to eq(:established)
      expect(target.attendees['agent-1'][:mutual_awareness]).to be true
      expect(target.attendees['agent-2'][:mutual_awareness]).to be true
    end

    it 'returns :target_not_found for unknown target' do
      result = manager.establish_shared(target_id: 'bogus', agent_a: 'agent-1', agent_b: 'agent-2')
      expect(result).to eq(:target_not_found)
    end

    it 'records shared_awareness history event' do
      manager.establish_shared(target_id: target.id, agent_a: 'agent-1', agent_b: 'agent-2')
      events = manager.history.map { |h| h[:event] }
      expect(events).to include(:shared_awareness)
    end
  end

  describe '#update_gaze' do
    before { manager.join_target(target_id: target.id, agent_id: 'agent-1') }

    it 'updates gaze direction' do
      result = manager.update_gaze(target_id: target.id, agent_id: 'agent-1', gaze: :timeline)
      expect(result).to eq(:updated)
    end

    it 'returns :target_not_found for unknown target' do
      result = manager.update_gaze(target_id: 'bogus', agent_id: 'agent-1', gaze: :x)
      expect(result).to eq(:target_not_found)
    end
  end

  describe '#targets_for_agent' do
    it 'returns targets the agent is attending' do
      targets = manager.targets_for_agent(agent_id: 'agent-1')
      expect(targets).to include(target)
    end

    it 'returns empty array for unknown agent' do
      expect(manager.targets_for_agent(agent_id: 'nobody')).to eq([])
    end
  end

  describe '#attendees_for_target' do
    before { manager.join_target(target_id: target.id, agent_id: 'agent-2') }

    it 'returns attendee ids for target' do
      ids = manager.attendees_for_target(target_id: target.id)
      expect(ids).to include('agent-1', 'agent-2')
    end

    it 'returns empty array for unknown target' do
      expect(manager.attendees_for_target(target_id: 'bogus')).to eq([])
    end
  end

  describe '#shared_targets' do
    it 'returns targets attended by both agents' do
      manager.join_target(target_id: target.id, agent_id: 'agent-2')
      shared = manager.shared_targets(agent_a: 'agent-1', agent_b: 'agent-2')
      expect(shared).to include(target)
    end

    it 'returns empty array when no shared targets' do
      shared = manager.shared_targets(agent_a: 'agent-1', agent_b: 'loner')
      expect(shared).to be_empty
    end
  end

  describe '#decay_all' do
    it 'decays focus on all targets' do
      focus_before = target.focus_strength
      manager.decay_all
      expect(target.focus_strength).to be <= focus_before
    end

    it 'prunes faded targets' do
      t = manager.create_target(name: 'doomed', domain: :temp, priority: 0.1, creator: 'agent-x')
      # Drain all attendees so target can become faded
      manager.leave_target(target_id: t.id, agent_id: 'agent-x')
      200.times { manager.decay_all }
      expect(manager.targets).not_to have_key(t.id)
    end
  end

  describe '#target_count' do
    it 'returns number of active targets' do
      manager.create_target(name: 'b', domain: :d, priority: 0.5, creator: 'a')
      expect(manager.target_count).to eq(2)
    end
  end

  describe '#to_h' do
    it 'returns a summary hash' do
      h = manager.to_h
      expect(h).to include(:target_count, :agent_count, :history_size, :targets)
    end

    it 'reflects correct target count' do
      expect(manager.to_h[:target_count]).to eq(1)
    end
  end
end
