# frozen_string_literal: true

RSpec.describe Legion::Extensions::JointAttention::Client do
  subject(:client) { described_class.new }

  it 'instantiates without arguments' do
    expect(client).to be_a(described_class)
  end

  it 'accepts an injected joint_focus_manager' do
    mgr = Legion::Extensions::JointAttention::Helpers::JointFocusManager.new
    c = described_class.new(joint_focus_manager: mgr)
    expect(c).to be_a(described_class)
  end

  it 'includes runner methods' do
    expect(client).to respond_to(:create_attention_target)
    expect(client).to respond_to(:join_attention)
    expect(client).to respond_to(:leave_attention)
    expect(client).to respond_to(:direct_attention)
    expect(client).to respond_to(:establish_mutual_awareness)
    expect(client).to respond_to(:update_gaze)
    expect(client).to respond_to(:shared_focus)
    expect(client).to respond_to(:attention_targets_for)
    expect(client).to respond_to(:update_joint_attention)
    expect(client).to respond_to(:joint_attention_stats)
  end

  it 'two clients maintain independent state' do
    c1 = described_class.new
    c2 = described_class.new
    c1.create_attention_target(name: 'only-in-c1', domain: :test, creator: 'agent-1')
    expect(c1.joint_attention_stats[:stats][:target_count]).to eq(1)
    expect(c2.joint_attention_stats[:stats][:target_count]).to eq(0)
  end
end
