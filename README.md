# REM.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://simoneSantoni.github.io/REM.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://simoneSantoni.github.io/REM.jl/dev/)
[![Build Status](https://github.com/simoneSantoni/REM.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/simoneSantoni/REM.jl/actions/workflows/CI.yml)

A Julia implementation of **Relational Event Models** for statistical analysis of time-stamped relational events in networks.

REM.jl is a port of [eventnet](https://github.com/juergenlerner/eventnet), providing efficient tools for modeling sequences of directed interactions between actors.

## What are Relational Event Models?

Relational Event Models (REM) are statistical models for analyzing sequences of time-stamped relational events. They help uncover factors explaining why certain actors interact at higher rates than others, taking into account:

- **Dyadic effects**: Repetition, reciprocity, and inertia
- **Actor effects**: Activity and popularity patterns
- **Structural effects**: Triadic closure, four-cycles, and clustering
- **Attribute effects**: Homophily and covariate effects

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/simoneSantoni/REM.jl")
```

## Quick Start

```julia
using REM

# Create an event sequence
events = [
    Event(1, 2, 1.0),  # Actor 1 sends to Actor 2 at time 1.0
    Event(2, 1, 2.0),  # Actor 2 sends to Actor 1 at time 2.0
    Event(1, 3, 3.0),  # Actor 1 sends to Actor 3 at time 3.0
    Event(3, 2, 4.0),  # Actor 3 sends to Actor 2 at time 4.0
]
seq = EventSequence(events)

# Define statistics to model
stats = [
    Repetition(),        # Tendency to repeat past interactions
    Reciprocity(),       # Tendency to reciprocate
    SenderActivity(),    # Sender's past activity level
    ReceiverPopularity() # Receiver's past popularity
]

# Fit the model
result = fit_rem(seq, stats; n_controls=100, seed=42)

# View results
println(result)
```

## Features

### Core Data Types

- `Event{T}` - Single relational event with sender, receiver, timestamp, type, and weight
- `EventSequence{T}` - Time-sorted collection of events
- `NetworkState{T}` - Efficient tracking of cumulative network state

### Available Statistics

**Dyad Statistics**
- `Repetition` - Past events from sender to receiver
- `Reciprocity` - Past events from receiver to sender
- `InertiaStatistic` - Combined repetition and reciprocity
- `RecencyStatistic` - Time since last event on dyad

**Degree Statistics**
- `SenderActivity` - Sender's out-degree
- `ReceiverActivity` - Receiver's out-degree
- `SenderPopularity` - Sender's in-degree
- `ReceiverPopularity` - Receiver's in-degree
- `TotalDegree`, `DegreeDifference`, `LogDegree`

**Triangle Statistics**
- `TransitiveClosure` - s->k->r patterns
- `CyclicClosure` - r->k->s patterns
- `SharedSender` - k->s and k->r patterns
- `SharedReceiver` - s->k and r->k patterns
- `CommonNeighbors`, `GeometricWeightedTriads`

**Four-Cycle Statistics**
- `FourCycle` - Various four-cycle configurations
- `GeometricWeightedFourCycles`

**Node Attribute Statistics**
- `NodeMatch` - Homophily (matching attributes)
- `NodeMix` - Specific sender-receiver combinations
- `NodeDifference`, `NodeSum`, `NodeProduct`
- `SenderAttribute`, `ReceiverAttribute`
- `SenderCategorical`, `ReceiverCategorical`

### Estimation

REM.jl uses case-control sampling with stratified conditional logistic regression:

```julia
# Generate observations with case-control sampling
sampler = CaseControlSampler(n_controls=100, seed=42)
obs = generate_observations(seq, stats, sampler)

# Fit model
result = fit_rem(obs, [name(s) for s in stats])

# Access results
coef(result)       # Coefficients
stderror(result)   # Standard errors
coeftable(result)  # Full coefficient table
```

### Temporal Decay

Support for exponential decay of network effects:

```julia
# Convert halflife to decay rate (e.g., 10 time units)
decay = halflife_to_decay(10.0)

# Create network state with decay
state = NetworkState(seq; decay=decay)

# Fit model with decay
result = fit_rem(seq, stats; n_controls=100, decay=decay)
```

### Loading Data

```julia
using DataFrames

# From DataFrame
df = DataFrame(sender=[1,2,1], receiver=[2,1,3], time=[1.0,2.0,3.0])
seq = load_events(df)

# From CSV
seq = load_events("events.csv")

# With string actor names
seq = load_events(df; actor_names=true)
```

## Documentation

For more detailed documentation, see:

- [Stable Documentation](https://simoneSantoni.github.io/REM.jl/stable/)
- [Development Documentation](https://simoneSantoni.github.io/REM.jl/dev/)

## References

- Butts, C. T. (2008). A relational event framework for social action. *Sociological Methodology*, 38(1), 155-200.
- Lerner, J., & Lomi, A. (2020). Reliability of relational event model estimates under sampling: How to fit a relational event model to 360 million dyadic events. *Network Science*, 8(1), 97-135.

## License

MIT License - see [LICENSE](LICENSE) for details.
