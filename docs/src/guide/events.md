# Events and Data

This guide covers how to work with relational event data in REM.jl.

## Events

An `Event` represents a single directed interaction:

```julia
# Basic event: sender, receiver, time
e = Event(1, 2, 1.0)

# With optional event type and weight
e = Event(1, 2, 1.0; eventtype=:email, weight=2.0)
```

### Event Fields

- `sender::Int` - ID of the event sender
- `receiver::Int` - ID of the event receiver
- `time::T` - Timestamp (can be Float64, Int, DateTime, or Date)
- `eventtype::Symbol` - Category of the event (default: `:event`)
- `weight::Float64` - Weight/magnitude (default: `1.0`)

### Timestamp Types

REM.jl supports various timestamp types:

```julia
using Dates

# Numeric timestamps
Event(1, 2, 1.0)         # Float64
Event(1, 2, 1)           # Int

# Calendar timestamps
Event(1, 2, DateTime(2024, 1, 15, 10, 30))  # DateTime
Event(1, 2, Date(2024, 1, 15))              # Date
```

## Event Sequences

An `EventSequence` is a time-sorted collection of events:

```julia
events = [
    Event(1, 2, 3.0),  # Not in order...
    Event(2, 1, 1.0),
    Event(1, 3, 2.0),
]
seq = EventSequence(events)  # Automatically sorted by time

# Access events
seq[1]              # First event (time=1.0)
length(seq)         # Number of events
seq.n_actors        # Number of unique actors
seq.actors          # Set of actor IDs
```

### Adding Events

```julia
# Events are inserted in time order
push!(seq, Event(3, 1, 1.5))
```

## Loading Data

### From DataFrame

```julia
using DataFrames

df = DataFrame(
    sender = [1, 2, 1],
    receiver = [2, 1, 3],
    time = [1.0, 2.0, 3.0]
)

seq = load_events(df)
```

### Custom Column Names

```julia
df = DataFrame(
    from = [1, 2, 1],
    to = [2, 1, 3],
    timestamp = [1.0, 2.0, 3.0],
    type = [:email, :email, :meeting],
    importance = [1.0, 2.0, 1.5]
)

seq = load_events(df;
    sender_col = :from,
    receiver_col = :to,
    time_col = :timestamp,
    type_col = :type,
    weight_col = :importance
)
```

### String Actor Names

When actors are identified by names rather than numeric IDs:

```julia
df = DataFrame(
    sender = ["Alice", "Bob", "Alice"],
    receiver = ["Bob", "Alice", "Carol"],
    time = [1.0, 2.0, 3.0]
)

seq = load_events(df; actor_names=true)
# Actors are assigned numeric IDs internally
```

### From CSV File

```julia
seq = load_events("events.csv")

# With options
seq = load_events("events.csv";
    sender_col = :source,
    receiver_col = :target,
    time_col = :timestamp,
    actor_names = true
)
```

### DateTime Parsing

```julia
df = DataFrame(
    sender = [1, 2, 1],
    receiver = [2, 1, 3],
    time = ["2024-01-01T10:00:00", "2024-01-01T11:00:00", "2024-01-01T12:00:00"]
)

seq = load_events(df; time_type=DateTime)
```

## Node Attributes

Node attributes store actor-level covariates:

```julia
# Create an attribute
gender = NodeAttribute(:gender,
    Dict(1 => "M", 2 => "F", 3 => "M"),  # Actor ID → value
    "Unknown"                             # Default value
)

# Access values
gender[1]  # "M"
gender[4]  # "Unknown" (default)

# Create numeric attribute
age = NodeAttribute(:age,
    Dict(1 => 25.0, 2 => 30.0, 3 => 28.0),
    0.0
)
```

## Actor Sets

For specifying custom risk sets:

```julia
# From numeric IDs
actors = ActorSet([1, 2, 3, 4, 5])

# From names (creates ID mapping)
actors = ActorSet(["Alice", "Bob", "Carol"])
actors.name_to_id["Alice"]  # 1
actors.id_to_name[1]        # "Alice"
```

## Risk Sets

Risk sets define which dyads could potentially experience an event:

```julia
rs = RiskSet(
    event_index,                    # Index of focal event
    [1, 2, 3],                      # Potential senders
    [1, 2, 3, 4];                   # Potential receivers
    exclude_self_loops = true       # Exclude s == r
)

n_dyads(rs)  # Number of dyads in risk set
```

## Utility Functions

### Time Windows

```julia
# Get events before a specific index
events_before(seq, 5)  # View of events 1:4

# Get events in a time window
events_in_window(seq, 5, 10.0)  # Events within 10 time units before event 5
```

### Decay Conversion

```julia
# Convert halflife to decay rate
decay = halflife_to_decay(10.0)  # λ such that weight = 0.5 at t = 10

# Convert back
halflife = decay_to_halflife(decay)
```
