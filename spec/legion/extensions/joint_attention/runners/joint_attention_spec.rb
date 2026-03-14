# frozen_string_literal: true

RSpec.describe Legion::Extensions::JointAttention::Runners::JointAttention do
  let(:client) { Legion::Extensions::JointAttention::Client.new }

  let!(:target_result) do
    client.create_attention_target(name: 'shared-task', domain: :work, priority: 0.7, creator: 'agent-1')
  end
  let(:target_id) { target_result[:target][:id] }

  describe '#create_attention_target' do
    it 'returns success: true' do
      expect(target_result[:success]).to be true
    end

    it 'returns target with all fields' do
      t = target_result[:target]
      expect(t).to include(:id, :name, :domain, :priority, :creator_agent_id, :created_at, :attendee_count)
    end

    it 'sets the name correctly' do
      expect(target_result[:target][:name]).to eq('shared-task')
    end

    it 'uses default priority when not specified' do
      result = client.create_attention_target(name: 'default-prio', domain: :x, creator: 'a')
      const = Legion::Extensions::JointAttention::Helpers::Constants::DEFAULT_FOCUS
      expect(result[:target][:priority]).to be_within(0.01).of(const)
    end

    it 'auto-joins the creator' do
      expect(target_result[:target][:attendee_count]).to eq(1)
    end
  end

  describe '#join_attention' do
    it 'joins a second agent and returns success' do
      result = client.join_attention(target_id: target_id, agent_id: 'agent-2')
      expect(result[:success]).to be true
      expect(result[:result]).to eq(:joined)
    end

    it 'returns success for already_attending' do
      client.join_attention(target_id: target_id, agent_id: 'agent-2')
      result = client.join_attention(target_id: target_id, agent_id: 'agent-2')
      expect(result[:success]).to be true
      expect(result[:result]).to eq(:already_attending)
    end

    it 'returns success: false for unknown target' do
      result = client.join_attention(target_id: 'bogus', agent_id: 'agent-2')
      expect(result[:success]).to be false
      expect(result[:result]).to eq(:target_not_found)
    end

    it 'includes target_id and agent_id in response' do
      result = client.join_attention(target_id: target_id, agent_id: 'agent-2')
      expect(result[:target_id]).to eq(target_id)
      expect(result[:agent_id]).to eq('agent-2')
    end

    it 'accepts a gaze keyword' do
      result = client.join_attention(target_id: target_id, agent_id: 'agent-2', gaze: :deadline)
      expect(result[:success]).to be true
    end
  end

  describe '#leave_attention' do
    before { client.join_attention(target_id: target_id, agent_id: 'agent-2') }

    it 'removes the agent and returns success' do
      result = client.leave_attention(target_id: target_id, agent_id: 'agent-2')
      expect(result[:success]).to be true
      expect(result[:result]).to eq(:removed)
    end

    it 'returns success: false for not_found' do
      result = client.leave_attention(target_id: target_id, agent_id: 'never-joined')
      expect(result[:success]).to be false
    end

    it 'returns success: false for unknown target' do
      result = client.leave_attention(target_id: 'bogus', agent_id: 'agent-2')
      expect(result[:success]).to be false
    end
  end

  describe '#direct_attention' do
    it 'directs to_agent to target and returns success' do
      result = client.direct_attention(from_agent: 'agent-1', to_agent: 'agent-2', target_id: target_id)
      expect(result[:success]).to be true
      expect(result[:result]).to eq(:directed)
    end

    it 'returns success: false for unknown target' do
      result = client.direct_attention(from_agent: 'agent-1', to_agent: 'agent-2', target_id: 'bogus')
      expect(result[:success]).to be false
    end

    it 'returns success: false when referrer is not attending' do
      result = client.direct_attention(from_agent: 'nobody', to_agent: 'agent-2', target_id: target_id)
      expect(result[:success]).to be false
      expect(result[:result]).to eq(:referrer_not_attending)
    end

    it 'includes from_agent and to_agent in response' do
      result = client.direct_attention(from_agent: 'agent-1', to_agent: 'agent-2', target_id: target_id)
      expect(result[:from_agent]).to eq('agent-1')
      expect(result[:to_agent]).to eq('agent-2')
    end
  end

  describe '#establish_mutual_awareness' do
    before { client.join_attention(target_id: target_id, agent_id: 'agent-2') }

    it 'establishes shared awareness and returns success' do
      result = client.establish_mutual_awareness(target_id: target_id, agent_a: 'agent-1', agent_b: 'agent-2')
      expect(result[:success]).to be true
      expect(result[:result]).to eq(:established)
    end

    it 'returns success: false for unknown target' do
      result = client.establish_mutual_awareness(target_id: 'bogus', agent_a: 'agent-1', agent_b: 'agent-2')
      expect(result[:success]).to be false
    end

    it 'returns success: false when one agent is not attending' do
      result = client.establish_mutual_awareness(target_id: target_id, agent_a: 'agent-1', agent_b: 'stranger')
      expect(result[:success]).to be false
    end

    it 'includes agent_a and agent_b in response' do
      result = client.establish_mutual_awareness(target_id: target_id, agent_a: 'agent-1', agent_b: 'agent-2')
      expect(result[:agent_a]).to eq('agent-1')
      expect(result[:agent_b]).to eq('agent-2')
    end
  end

  describe '#update_gaze' do
    it 'updates gaze direction and returns success' do
      result = client.update_gaze(target_id: target_id, agent_id: 'agent-1', gaze: :risk)
      expect(result[:success]).to be true
      expect(result[:result]).to eq(:updated)
      expect(result[:gaze]).to eq(:risk)
    end

    it 'returns success: false for unknown target' do
      result = client.update_gaze(target_id: 'bogus', agent_id: 'agent-1', gaze: :risk)
      expect(result[:success]).to be false
    end

    it 'returns success: false for unknown agent' do
      result = client.update_gaze(target_id: target_id, agent_id: 'nobody', gaze: :risk)
      expect(result[:success]).to be false
    end
  end

  describe '#shared_focus' do
    it 'returns shared targets between two agents' do
      client.join_attention(target_id: target_id, agent_id: 'agent-2')
      result = client.shared_focus(agent_a: 'agent-1', agent_b: 'agent-2')
      expect(result[:success]).to be true
      expect(result[:count]).to eq(1)
      expect(result[:shared_targets].first[:id]).to eq(target_id)
    end

    it 'returns empty when no shared targets' do
      result = client.shared_focus(agent_a: 'agent-1', agent_b: 'loner')
      expect(result[:success]).to be true
      expect(result[:count]).to eq(0)
      expect(result[:shared_targets]).to be_empty
    end

    it 'includes agent_a and agent_b in response' do
      result = client.shared_focus(agent_a: 'agent-1', agent_b: 'agent-2')
      expect(result[:agent_a]).to eq('agent-1')
      expect(result[:agent_b]).to eq('agent-2')
    end
  end

  describe '#attention_targets_for' do
    it 'returns targets for an agent' do
      result = client.attention_targets_for(agent_id: 'agent-1')
      expect(result[:success]).to be true
      expect(result[:count]).to eq(1)
      expect(result[:targets].first[:id]).to eq(target_id)
    end

    it 'returns empty for unknown agent' do
      result = client.attention_targets_for(agent_id: 'nobody')
      expect(result[:success]).to be true
      expect(result[:count]).to eq(0)
    end

    it 'includes agent_id in response' do
      result = client.attention_targets_for(agent_id: 'agent-1')
      expect(result[:agent_id]).to eq('agent-1')
    end
  end

  describe '#update_joint_attention' do
    it 'returns success with stats' do
      result = client.update_joint_attention
      expect(result[:success]).to be true
      expect(result).to have_key(:targets)
      expect(result).to have_key(:agents)
      expect(result).to have_key(:history)
    end

    it 'reflects current target count' do
      result = client.update_joint_attention
      expect(result[:targets]).to be >= 1
    end
  end

  describe '#joint_attention_stats' do
    it 'returns success with full stats hash' do
      result = client.joint_attention_stats
      expect(result[:success]).to be true
      expect(result[:stats]).to include(:target_count, :agent_count, :history_size, :targets)
    end

    it 'stats reflect created targets' do
      stats = client.joint_attention_stats
      expect(stats[:stats][:target_count]).to eq(1)
    end
  end
end
