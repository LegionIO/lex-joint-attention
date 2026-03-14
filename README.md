# lex-joint-attention

Shared attention coordination for LegionIO multi-agent environments. Part of the LegionIO cognitive architecture extension ecosystem (LEX).

## What It Does

`lex-joint-attention` lets multiple agents coordinate their attention on common targets. Agents can create shared attention targets, join them with a focus value, direct each other's attention, and establish mutual awareness (with a focus bonus). Focus values decay over time, and faded targets are automatically pruned. Models the social cognitive ability to attend to the same object as another agent.

Key capabilities:

- **Shared attention targets**: any agent can create a named target in a domain
- **Referral boost**: directing another agent's attention applies a 0.2 focus boost
- **Mutual awareness**: explicit establishment between two agents applies a 0.15 focus bonus
- **Focus decay**: per-attendee focus decays 0.015 per tick; faded attendees and targets pruned automatically
- **Focus labels**: focused / attending / peripheral / fading per focus value

## Installation

Add to your Gemfile:

```ruby
gem 'lex-joint-attention'
```

Or install directly:

```
gem install lex-joint-attention
```

## Usage

```ruby
require 'legion/extensions/joint_attention'

client = Legion::Extensions::JointAttention::Client.new

# Create a shared target
target = client.create_attention_target(content: 'critical bug #4821', domain: :debugging)
target_id = target[:target][:id]

# Multiple agents join
client.join_attention(target_id: target_id, agent_id: 'agent-1', focus: 0.8)
client.join_attention(target_id: target_id, agent_id: 'agent-2', focus: 0.5)

# Direct attention
client.direct_attention(target_id: target_id, from_agent: 'agent-1', to_agent: 'agent-2')

# Establish mutual awareness
client.establish_mutual_awareness(target_id: target_id, agent_a: 'agent-1', agent_b: 'agent-2')

# See what an agent is attending to
client.shared_focus(agent_id: 'agent-1')

# Stats
client.joint_attention_stats
```

## Runner Methods

| Method | Description |
|---|---|
| `create_attention_target` | Create a new shared attention target |
| `join_attention` | Join an attention target with initial focus |
| `leave_attention` | Leave an attention target |
| `direct_attention` | Direct another agent's attention with referral boost |
| `establish_mutual_awareness` | Establish mutual awareness between two agents |
| `update_gaze` | Update a specific agent's focus value |
| `shared_focus` | All targets the agent is currently attending |
| `attention_targets_for` | All targets in a given domain |
| `update_joint_attention` | Decay cycle (also runs automatically via actor) |
| `joint_attention_stats` | Target count, total attendees, avg focus |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
