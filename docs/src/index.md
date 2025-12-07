# REM.jl

*Relational Event Models for Julia*

REM.jl is a Julia implementation for statistical analysis of relational event networks. It is a port of [eventnet](https://github.com/juergenlerner/eventnet).

## What are Relational Event Models?

Relational Event Models (REM) are statistical models for analyzing sequences of time-stamped relational events. An event is a directed interaction from a sender to a receiver at a specific point in time. REMs help uncover factors explaining why certain actors interact at higher rates than others.

### Key Concepts

- **Relational Event**: A time-stamped directed interaction (sender → receiver)
- **Event Sequence**: A chronologically ordered sequence of relational events
- **Network State**: The cumulative state of interactions up to a point in time
- **Statistics**: Computed features that predict event occurrence

### Applications

REMs are widely used in:
- Social network analysis
- Communication networks (email, messaging)
- Organizational studies
- International relations
- Animal behavior studies

## Features

- **Efficient computation**: Incremental network state updates for fast statistic calculation
- **Rich statistic library**: Dyadic, degree, triadic, four-cycle, and node attribute statistics
- **Temporal decay**: Support for exponential decay of network effects
- **Case-control sampling**: Efficient estimation for large networks
- **Flexible data input**: Load events from DataFrames or CSV files

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/simoneSantoni/REM.jl")
```

## Quick Example

```julia
using REM

# Create events
events = [
    Event(1, 2, 1.0),
    Event(2, 1, 2.0),
    Event(1, 3, 3.0),
]
seq = EventSequence(events)

# Define model statistics
stats = [Repetition(), Reciprocity(), SenderActivity()]

# Fit model
result = fit_rem(seq, stats; n_controls=100, seed=42)
println(result)
```

## Contents

```@contents
Pages = [
    "getting_started.md",
    "guide/events.md",
    "guide/statistics.md",
    "guide/estimation.md",
    "guide/decay.md",
    "api/types.md",
    "api/statistics.md",
    "api/estimation.md",
]
Depth = 2
```

## References

- Butts, C. T. (2008). A relational event framework for social action. *Sociological Methodology*, 38(1), 155-200.
- Lerner, J., & Lomi, A. (2020). Reliability of relational event model estimates under sampling. *Network Science*, 8(1), 97-135.
