# Estimation API Reference

This page documents the functions for data loading, observation generation, and model fitting.

## Data Loading

### load_events

```@docs
load_events
```

## Observation Generation

### CaseControlSampler

```@docs
CaseControlSampler
```

### generate_observations

```@docs
generate_observations
```

### compute_statistics

```@docs
compute_statistics
```

## Model Fitting

### fit_rem

```@docs
fit_rem
```

### REMResult

```@docs
REMResult
```

### Result Accessors

```@docs
coef
stderror
coeftable
```

## Utility Functions

### Time Decay

```@docs
halflife_to_decay
decay_to_halflife
compute_decay_weight
```

### Risk Set Utilities

```@docs
n_dyads
```
