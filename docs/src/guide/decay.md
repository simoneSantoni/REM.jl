# Temporal Decay

REM.jl supports exponential decay of network effects, allowing past events to have diminishing influence over time.

## Why Use Decay?

In many applications, recent events are more relevant than older ones:

- A communication last week matters more than one from a year ago
- Relationships may weaken without recent interaction
- Network effects fade over time

Temporal decay captures this by down-weighting older events.

## Exponential Decay Model

The weight of an event decays exponentially:

```
weight(t) = exp(-λ × elapsed_time)
```

Where:
- λ is the decay rate
- At t=0, weight = 1.0
- At halflife, weight = 0.5

## Setting Decay Rate

### Using Halflife

The most intuitive way is to specify a halflife:

```julia
# Events lose half their weight after 10 time units
decay = halflife_to_decay(10.0)
```

### Direct Decay Rate

```julia
# Decay rate of 0.1 per time unit
decay = 0.1
```

### Converting Between Forms

```julia
decay = halflife_to_decay(halflife)
halflife = decay_to_halflife(decay)
```

## Using Decay in Models

### With fit_rem

```julia
result = fit_rem(seq, stats;
    n_controls = 100,
    decay = halflife_to_decay(10.0),
    seed = 42
)
```

### With NetworkState

```julia
# Create state with decay
state = NetworkState(seq; decay=halflife_to_decay(10.0))

# Process events - decay is applied automatically
for event in seq
    update!(state, event)
end
```

### With generate_observations

```julia
sampler = CaseControlSampler(n_controls=100, seed=42)
obs = generate_observations(seq, stats, sampler;
    decay = halflife_to_decay(10.0)
)
```

## Decay with Different Time Types

### Numeric Timestamps

For numeric timestamps, decay is applied directly:

```julia
# If time is in hours, halflife of 24 = one day decay
decay = halflife_to_decay(24.0)
```

### DateTime Timestamps

For DateTime, time differences are converted to seconds:

```julia
using Dates

events = [
    Event(1, 2, DateTime(2024, 1, 1, 10, 0)),
    Event(2, 1, DateTime(2024, 1, 1, 11, 0)),
]
seq = EventSequence(events)

# Halflife of 1 hour = 3600 seconds
decay = halflife_to_decay(3600.0)
state = NetworkState(seq; decay=decay)
```

### Date Timestamps

For Date, differences are in days (converted to seconds):

```julia
events = [
    Event(1, 2, Date(2024, 1, 1)),
    Event(2, 1, Date(2024, 1, 15)),
]
seq = EventSequence(events)

# Halflife of 7 days = 7 * 86400 seconds
decay = halflife_to_decay(7.0 * 86400)
```

## How Decay Affects Statistics

### Dyad Counts

Without decay:
```
get_dyad_count(state, s, r) = total number of s→r events
```

With decay:
```
get_dyad_count(state, s, r) = Σ exp(-λ × (current_time - event_time))
```

### Degrees

Out-degree and in-degree are similarly weighted:
```
out_degree(actor) = Σ decay_weight × event_weight
```

### Example

```julia
using REM

events = [
    Event(1, 2, 0.0),
    Event(1, 2, 10.0),  # 10 time units later
]
seq = EventSequence(events)

# Halflife of 10
decay = halflife_to_decay(10.0)
state = NetworkState(seq; decay=decay)

# After first event
update!(state, seq[1])
println(get_dyad_count(state, 1, 2))  # 1.0

# After second event (first event decayed to 0.5)
update!(state, seq[2])
println(get_dyad_count(state, 1, 2))  # 1.5 (0.5 + 1.0)
```

## Choosing Halflife

The appropriate halflife depends on your domain:

| Domain | Typical Halflife |
|--------|------------------|
| Email/messaging | Hours to days |
| Social interactions | Days to weeks |
| Business relationships | Weeks to months |
| Organizational ties | Months to years |

### Guidelines

1. **Domain knowledge**: What timeframe makes interactions "stale"?
2. **Event frequency**: Halflife should be comparable to typical inter-event times
3. **Sensitivity analysis**: Try different values and compare results

## Recency Statistic

For dyad-specific recency effects, use `RecencyStatistic`:

```julia
# Inverse of time since last event
RecencyStatistic(transform=:inverse)

# With exponential decay
RecencyStatistic(transform=:exp_decay, decay=0.1)

# Log transform
RecencyStatistic(transform=:log)
```

This is different from global decay:
- **Global decay**: Affects all statistics through NetworkState
- **RecencyStatistic**: A specific statistic measuring time since last dyad event

## Combining Approaches

You can use both:

```julia
stats = [
    Repetition(),           # Affected by global decay
    Reciprocity(),          # Affected by global decay
    RecencyStatistic(),     # Additional dyad-specific recency effect
]

result = fit_rem(seq, stats;
    n_controls = 100,
    decay = halflife_to_decay(10.0),  # Global decay
    seed = 42
)
```

This allows modeling both:
- General decay of all network effects
- Specific recency effects for focal dyads
