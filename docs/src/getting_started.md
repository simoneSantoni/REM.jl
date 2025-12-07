# Getting Started

This guide will help you get started with REM.jl for analyzing relational event data.

## Installation

Install REM.jl from GitHub:

```julia
using Pkg
Pkg.add(url="https://github.com/simoneSantoni/REM.jl")
```

## Basic Workflow

The typical REM.jl workflow consists of four steps:

1. **Load or create events** - Prepare your relational event data
2. **Define statistics** - Choose which effects to model
3. **Fit the model** - Estimate coefficients
4. **Interpret results** - Analyze the fitted model

## Step 1: Create an Event Sequence

Events represent directed interactions between actors at specific times:

```julia
using REM

# Create individual events: Event(sender, receiver, time)
events = [
    Event(1, 2, 1.0),   # Actor 1 → Actor 2 at time 1.0
    Event(2, 1, 2.0),   # Actor 2 → Actor 1 at time 2.0
    Event(1, 3, 3.0),   # Actor 1 → Actor 3 at time 3.0
    Event(3, 2, 4.0),   # Actor 3 → Actor 2 at time 4.0
    Event(2, 3, 5.0),   # Actor 2 → Actor 3 at time 5.0
    Event(1, 2, 6.0),   # Actor 1 → Actor 2 at time 6.0
]

# Create an EventSequence (automatically sorted by time)
seq = EventSequence(events)

println("Number of events: ", length(seq))
println("Number of actors: ", seq.n_actors)
```

### Loading from a DataFrame

More commonly, you'll load events from existing data:

```julia
using DataFrames

df = DataFrame(
    sender = [1, 2, 1, 3, 2, 1],
    receiver = [2, 1, 3, 2, 3, 2],
    time = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]
)

seq = load_events(df)
```

### Loading from CSV

```julia
seq = load_events("path/to/events.csv")
```

## Step 2: Define Statistics

Statistics capture different mechanisms that might drive event occurrence:

```julia
# Basic dyadic statistics
stats = [
    Repetition(),           # Past events from sender to receiver
    Reciprocity(),          # Past events from receiver to sender
    SenderActivity(),       # Sender's overall activity (out-degree)
    ReceiverPopularity(),   # Receiver's overall popularity (in-degree)
]
```

### Exploring Available Statistics

REM.jl provides many statistics organized by type:

```julia
# Dyad statistics - history between the focal dyad
Repetition()              # s→r history
Reciprocity()             # r→s history
InertiaStatistic()        # Combined repetition and reciprocity
RecencyStatistic()        # Time since last s→r event

# Degree statistics - actor activity/popularity
SenderActivity()          # Sender's out-degree
ReceiverActivity()        # Receiver's out-degree
SenderPopularity()        # Sender's in-degree
ReceiverPopularity()      # Receiver's in-degree

# Triangle statistics - triadic closure
TransitiveClosure()       # s→k→r patterns (friends of friends)
CyclicClosure()           # r→k→s patterns
SharedSender()            # k→s and k→r patterns
SharedReceiver()          # s→k and r→k patterns
```

## Step 3: Fit the Model

Use `fit_rem` to estimate the model:

```julia
result = fit_rem(seq, stats; n_controls=100, seed=42)
```

Key parameters:
- `n_controls`: Number of control samples per event (higher = more accurate, slower)
- `seed`: Random seed for reproducibility
- `decay`: Exponential decay rate for temporal effects (default: 0.0 = no decay)

## Step 4: Interpret Results

The result object contains coefficient estimates and test statistics:

```julia
# Print summary table
println(result)

# Access specific values
coef(result)        # Vector of coefficients
stderror(result)    # Standard errors
coeftable(result)   # Full table as DataFrame
```

### Interpreting Coefficients

- **Positive coefficient**: The statistic increases the rate of events
- **Negative coefficient**: The statistic decreases the rate of events
- **Coefficients are log-hazard ratios**: exp(coef) gives the multiplicative effect

Example interpretation:
- `repetition = 0.5` means each past s→r event increases the rate by a factor of exp(0.5) ≈ 1.65
- `reciprocity = 0.8` means events are exp(0.8) ≈ 2.2 times more likely when r→s has occurred

## Complete Example

```julia
using REM
using DataFrames

# Simulate some event data
events = [
    Event(1, 2, 1.0),
    Event(2, 1, 2.0),
    Event(1, 2, 3.0),  # Repetition of 1→2
    Event(2, 3, 4.0),
    Event(3, 1, 5.0),
    Event(1, 3, 6.0),  # Reciprocity of 3→1
]
seq = EventSequence(events)

# Define model
stats = [
    Repetition(),
    Reciprocity(),
    SenderActivity(),
    ReceiverPopularity(),
    TransitiveClosure(),
]

# Fit with case-control sampling
result = fit_rem(seq, stats; n_controls=50, seed=123)

# View results
println(result)

# Get coefficient table
df = coeftable(result)
println(df)
```

## Next Steps

- Learn about [Events and Data](guide/events.md) for data handling
- Explore all [Statistics](guide/statistics.md) available
- Understand [Model Estimation](guide/estimation.md) in detail
- Use [Temporal Decay](guide/decay.md) for time-weighted effects
