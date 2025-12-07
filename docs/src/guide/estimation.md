# Model Estimation

REM.jl estimates relational event models using case-control sampling with stratified conditional logistic regression (equivalent to Cox proportional hazards for survival data).

## Case-Control Sampling

For large networks, computing statistics for all possible dyads is computationally expensive. Case-control sampling provides an efficient alternative:

1. For each observed event (case), sample a set of non-events (controls)
2. Compute statistics for both cases and controls
3. Estimate the model using stratified conditional logistic regression

```julia
# Configure sampling
sampler = CaseControlSampler(
    n_controls = 100,        # Controls per case
    exclude_self_loops = true,
    seed = 42                # For reproducibility
)
```

## Generating Observations

```julia
# Generate case-control observations
obs = generate_observations(seq, stats, sampler)
```

The resulting DataFrame contains:
- `event_index` - Index of the focal event
- `sender`, `receiver` - Dyad IDs
- `is_event` - True for cases, false for controls
- `stratum` - Stratum ID (groups cases with their controls)
- Columns for each statistic

### Options

```julia
generate_observations(seq, stats, sampler;
    start_index = 1,           # First event to include
    end_index = length(seq),   # Last event to include
    decay = 0.0,               # Exponential decay rate
    at_risk = nothing          # Custom set of actors at risk
)
```

## Fitting Models

### Direct Fitting

The simplest approach:

```julia
result = fit_rem(seq, stats;
    n_controls = 100,
    seed = 42
)
```

### Two-Stage Fitting

For more control:

```julia
# Stage 1: Generate observations
sampler = CaseControlSampler(n_controls=100, seed=42)
obs = generate_observations(seq, stats, sampler)

# Stage 2: Fit model
stat_names = [name(s) for s in stats]
result = fit_rem(obs, stat_names)
```

### Fit Options

```julia
fit_rem(obs, stat_names;
    maxiter = 100,   # Maximum Newton-Raphson iterations
    tol = 1e-8       # Convergence tolerance
)
```

## Results

The `REMResult` object contains:

```julia
result.coefficients    # Estimated coefficients
result.std_errors      # Standard errors
result.z_values        # Z-statistics
result.p_values        # Two-sided p-values
result.stat_names      # Statistic names
result.n_events        # Number of events
result.n_observations  # Total observations
result.log_likelihood  # Log-likelihood at convergence
result.converged       # Convergence indicator
```

### Accessor Functions

```julia
coef(result)        # Coefficients vector
stderror(result)    # Standard errors vector
coeftable(result)   # Full table as DataFrame
```

### Displaying Results

```julia
println(result)
```

Output:
```
Relational Event Model Results
==============================
Events: 100, Observations: 10100
Log-likelihood: -234.5678
Converged: true

Coefficients:
------------------------------------------------------------
Statistic                  Coef    Std.Err          z      P>|z|
------------------------------------------------------------
repetition               0.4523     0.0812     5.5700     0.0000 ***
reciprocity              0.3156     0.0923     3.4200     0.0006 ***
sender_activity          0.0234     0.0156     1.5000     0.1336
receiver_popularity      0.0567     0.0189     3.0000     0.0027 **
------------------------------------------------------------
Signif. codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
```

## Interpreting Coefficients

### Log-Hazard Ratios

Coefficients are log-hazard ratios. A coefficient β means:

- exp(β) is the multiplicative effect on the event rate
- β > 0 increases the rate
- β < 0 decreases the rate

### Example Interpretations

| Statistic | Coefficient | Interpretation |
|-----------|-------------|----------------|
| Repetition | 0.5 | Each past s→r event increases rate by 65% (exp(0.5) ≈ 1.65) |
| Reciprocity | 0.8 | Past r→s events increase rate by 123% (exp(0.8) ≈ 2.23) |
| SenderActivity | -0.1 | High-activity senders have slightly lower per-dyad rates |
| TransitiveClosure | 0.3 | Each shared partner increases rate by 35% |

## Computing Statistics Without Sampling

To compute statistics for actual events only (no controls):

```julia
stats_df = compute_statistics(seq, stats; decay=0.0)
```

This returns a DataFrame with one row per event and columns for:
- `sender`, `receiver`, `time`
- Each statistic value

## Model Selection

### Comparing Models

```julia
# Fit multiple models
stats1 = [Repetition(), Reciprocity()]
stats2 = [Repetition(), Reciprocity(), TransitiveClosure()]

result1 = fit_rem(seq, stats1; n_controls=100, seed=42)
result2 = fit_rem(seq, stats2; n_controls=100, seed=42)

# Compare log-likelihoods
println("Model 1 LL: ", result1.log_likelihood)
println("Model 2 LL: ", result2.log_likelihood)
```

### Checking Convergence

```julia
if !result.converged
    @warn "Model did not converge"
end
```

## Best Practices

1. **Number of controls**: More controls = more accurate estimates but slower computation. 50-200 is typically sufficient.

2. **Random seed**: Always set a seed for reproducibility.

3. **Check convergence**: Verify `result.converged == true`.

4. **Avoid multicollinearity**: Don't include highly correlated statistics.

5. **Scale statistics**: For very large networks, consider log-transforming degree statistics.

6. **Sufficient events**: Need enough events for stable estimation. Rule of thumb: at least 10 events per parameter.
