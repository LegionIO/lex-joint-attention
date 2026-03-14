# lex-joint-attention

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-joint-attention`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::JointAttention`

## Purpose

Shared attention coordination for LegionIO multi-agent environments. Allows agents to create shared attention targets, join or leave them, direct each other's attention via referral boosts, and establish mutual awareness with a shared awareness bonus. Focus values per attendee decay over time via a periodic actor. Models the social cognitive ability to coordinate attention on a common object or topic.

## Gem Info

- **Require path**: `legion/extensions/joint_attention`
- **Ruby**: >= 3.4
- **License**: MIT
- **Registers with**: `Legion::Extensions::Core`

## File Structure

```
lib/legion/extensions/joint_attention/
  version.rb
  helpers/
    constants.rb              # Limits, decay rates, labels
    attention_target.rb       # AttentionTarget value object
    joint_focus_manager.rb    # Shared attention registry
  actors/
    decay.rb                  # Focus decay actor
  runners/
    joint_attention.rb        # Runner module

spec/
  legion/extensions/joint_attention/
    helpers/
      constants_spec.rb
      attention_target_spec.rb
      joint_focus_manager_spec.rb
    actors/decay_spec.rb
    runners/joint_attention_spec.rb
  spec_helper.rb
```

## Key Constants

```ruby
MAX_TARGETS              = 100
MAX_ATTENDEES_PER_TARGET = 20
FOCUS_DECAY              = 0.015  # focus decrement per decay tick per attendee
FOCUS_ALPHA              = 0.12   # EMA factor for focus updates
SHARED_AWARENESS_BONUS   = 0.15   # focus boost when mutual awareness is established
REFERRAL_BOOST           = 0.2    # focus boost when attention is directed by another agent
MAX_SIMULTANEOUS_TARGETS = 5      # per-agent simultaneous target cap

FOCUS_LABELS = {
  (0.7..)     => :focused,
  (0.4...0.7) => :attending,
  (0.2...0.4) => :peripheral,
  (..0.2)     => :fading
}
```

## Helpers

### `Helpers::AttentionTarget` (class)

A shared object or topic that multiple agents are attending to.

| Attribute | Type | Description |
|---|---|---|
| `id` | String (UUID) | unique identifier |
| `content` | String | what the target is |
| `domain` | Symbol | subject domain |
| `attendees` | Hash | agent_id -> focus_value |
| `mutual_awareness` | Array<Array> | pairs of agents that have established mutual awareness |

Key methods:
- `add_attendee(agent_id, focus:)` — registers agent with initial focus; enforces MAX_ATTENDEES_PER_TARGET
- `remove_attendee(agent_id)` — removes agent from attendee list
- `boost_focus(agent_id, amount)` — increments agent's focus value (cap 1.0)
- `establish_mutual_awareness(agent_a, agent_b)` — records the pair; applies SHARED_AWARENESS_BONUS to both
- `decay(agent_id)` — subtracts FOCUS_DECAY from agent's focus
- `faded?` — true if all attendees have focus < 0.1
- `prune_faded_attendees` — removes attendees below 0.1 focus threshold

### `Helpers::JointFocusManager` (class)

Registry of all active attention targets.

| Method | Description |
|---|---|
| `create_target(content:, domain:)` | creates new attention target |
| `join_target(target_id:, agent_id:, focus:)` | adds agent to target's attendee list |
| `leave_target(target_id:, agent_id:)` | removes agent from target |
| `direct_attention(target_id:, from_agent:, to_agent:)` | applies REFERRAL_BOOST to to_agent's focus |
| `establish_shared(target_id:, agent_a:, agent_b:)` | establishes mutual awareness between two agents |
| `shared_targets(agent_id:)` | targets where given agent is attending |
| `decay_all` | decays all attendee focus values; removes faded targets |

## Actors

**`Actors::Decay`** — fires periodically, calls `update_joint_attention` on the runner to decay all focus values.

## Runners

Module: `Legion::Extensions::JointAttention::Runners::JointAttention`

Private state: `@manager` (memoized `JointFocusManager` instance).

| Runner Method | Parameters | Description |
|---|---|---|
| `create_attention_target` | `content:, domain:` | Create a new shared attention target |
| `join_attention` | `target_id:, agent_id:, focus: 0.5` | Join an attention target |
| `leave_attention` | `target_id:, agent_id:` | Leave an attention target |
| `direct_attention` | `target_id:, from_agent:, to_agent:` | Direct another agent's attention (referral boost) |
| `establish_mutual_awareness` | `target_id:, agent_a:, agent_b:` | Establish mutual awareness with bonus |
| `update_gaze` | `target_id:, agent_id:, focus:` | Update a specific agent's focus value |
| `shared_focus` | `agent_id:` | All targets the agent is attending |
| `attention_targets_for` | `domain:` | All targets in a given domain |
| `update_joint_attention` | (none) | Decay cycle (called by actor) |
| `joint_attention_stats` | (none) | Target count, total attendees, avg focus |

## Integration Points

- **lex-mesh**: joint attention requires agents to be discoverable via mesh; target creation and gaze direction are typically triggered by mesh message exchanges.
- **lex-swarm**: swarm agents coordinate on shared tasks; joint attention on a shared target models the cognitive alignment needed for effective swarm coordination.
- **lex-trust**: agents with higher trust establish mutual awareness more readily (caller responsibility to check trust before calling `establish_mutual_awareness`).
- **lex-metacognition**: `JointAttention` is listed under `:communication` capability category.

## Development Notes

- Focus values are per-attendee floats in the `attendees` hash keyed by agent_id string. There is no global target focus — focus is always relative to a specific attendee.
- `MAX_SIMULTANEOUS_TARGETS` is a documented constant but enforcement is the caller's responsibility (the manager does not enforce it).
- `decay_all` removes targets where `faded?` is true (all attendees below 0.1). Targets with zero attendees after decay are also removed.
- Mutual awareness is one-way recorded: calling `establish_mutual_awareness(target, a, b)` adds `[a,b]` to the pairs list but does not prevent duplicate entries. Callers should check existing pairs before calling.
- No actor for target creation; `decay_all` is the only actor-driven operation.
