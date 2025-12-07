"""
Observation generation for REM estimation.

Implements case-control sampling and observation generation for fitting
relational event models using survival analysis methods.
"""

"""
    Observation

A single observation for model estimation, consisting of:
- Statistics computed for a potential event (sender→receiver)
- Whether the event actually occurred (case) or not (control)

# Fields
- `event_index::Int`: Index of the focal event in the sequence
- `sender::Int`: Sender ID
- `receiver::Int`: Receiver ID
- `statistics::Vector{Float64}`: Computed statistic values
- `is_event::Bool`: True if this dyad actually had an event (case)
- `stratum::Int`: Stratum ID for stratified analysis (events in same stratum share risk set)
"""
struct Observation
    event_index::Int
    sender::Int
    receiver::Int
    statistics::Vector{Float64}
    is_event::Bool
    stratum::Int
end

"""
    CaseControlSampler

Generates observations using case-control sampling.
For each observed event (case), samples a specified number of non-events (controls)
from the risk set.

# Fields
- `n_controls::Int`: Number of control samples per case
- `exclude_self_loops::Bool`: Whether to exclude self-loops from sampling
- `seed::Union{Int, Nothing}`: Random seed for reproducibility
"""
struct CaseControlSampler
    n_controls::Int
    exclude_self_loops::Bool
    seed::Union{Int, Nothing}

    function CaseControlSampler(; n_controls::Int=100, exclude_self_loops::Bool=true,
                                 seed::Union{Int, Nothing}=nothing)
        n_controls > 0 || throw(ArgumentError("n_controls must be positive"))
        new(n_controls, exclude_self_loops, seed)
    end
end

"""
    generate_observations(seq::EventSequence, stats::Vector{<:AbstractStatistic},
                          sampler::CaseControlSampler; kwargs...) -> DataFrame

Generate observations for model estimation using case-control sampling.

# Arguments
- `seq::EventSequence`: The event sequence to analyze
- `stats::Vector{<:AbstractStatistic}`: Statistics to compute
- `sampler::CaseControlSampler`: Sampling configuration

# Keyword Arguments
- `start_index::Int=1`: Index of first event to include
- `end_index::Int=length(seq)`: Index of last event to include
- `decay::Float64=0.0`: Exponential decay rate for network state
- `at_risk::Union{Nothing, Set{Int}}=nothing`: Set of actors "at risk" (if nothing, all actors)

# Returns
- `DataFrame`: Observations with columns for each statistic, plus is_event and stratum
"""
function generate_observations(seq::EventSequence{T}, stats::Vector{<:AbstractStatistic},
                               sampler::CaseControlSampler;
                               start_index::Int=1, end_index::Int=length(seq),
                               decay::Float64=0.0,
                               at_risk::Union{Nothing, Set{Int}}=nothing) where T
    # Set random seed if specified
    if !isnothing(sampler.seed)
        Random.seed!(sampler.seed)
    end

    # Initialize network state
    state = NetworkState(seq; decay=decay)

    # Process events before start_index to build initial state
    for i in 1:(start_index - 1)
        update!(state, seq[i])
    end

    # Determine actors in risk set
    actors = isnothing(at_risk) ? collect(seq.actors) : collect(at_risk)
    n_actors = length(actors)

    # Pre-allocate observation storage
    observations = Observation[]
    stat_names = [name(s) for s in stats]

    # Process each event
    for event_idx in start_index:end_index
        event = seq[event_idx]

        # Update state time without adding the event yet
        if decay > 0 && event.time > state.current_time
            apply_decay!(state, event.time)
        end
        state.current_time = event.time

        # Compute statistics for the actual event (case)
        case_stats = compute_all(stats, state, event.sender, event.receiver)
        push!(observations, Observation(event_idx, event.sender, event.receiver,
                                        case_stats, true, event_idx))

        # Sample controls
        controls_sampled = 0
        max_attempts = sampler.n_controls * 10  # Prevent infinite loops
        attempts = 0

        while controls_sampled < sampler.n_controls && attempts < max_attempts
            attempts += 1

            # Randomly sample a sender and receiver
            s = actors[rand(1:n_actors)]
            r = actors[rand(1:n_actors)]

            # Skip self-loops if configured
            if sampler.exclude_self_loops && s == r
                continue
            end

            # Skip if this is the actual event
            if s == event.sender && r == event.receiver
                continue
            end

            # Compute statistics for control
            control_stats = compute_all(stats, state, s, r)
            push!(observations, Observation(event_idx, s, r, control_stats, false, event_idx))
            controls_sampled += 1
        end

        # Update state with the actual event
        update!(state, event)
    end

    # Convert to DataFrame
    return observations_to_dataframe(observations, stat_names)
end

"""
    observations_to_dataframe(observations::Vector{Observation}, stat_names::Vector{String}) -> DataFrame

Convert observations to a DataFrame.
"""
function observations_to_dataframe(observations::Vector{Observation}, stat_names::Vector{String})
    n_obs = length(observations)
    n_stats = length(stat_names)

    # Create columns
    data = Dict{String, Vector}()
    data["event_index"] = [o.event_index for o in observations]
    data["sender"] = [o.sender for o in observations]
    data["receiver"] = [o.receiver for o in observations]
    data["is_event"] = [o.is_event for o in observations]
    data["stratum"] = [o.stratum for o in observations]

    # Add statistic columns
    for (i, sname) in enumerate(stat_names)
        data[sname] = [o.statistics[i] for o in observations]
    end

    return DataFrame(data)
end

"""
    compute_statistics(seq::EventSequence, stats::Vector{<:AbstractStatistic};
                       decay::Float64=0.0) -> DataFrame

Compute statistics for all events in a sequence (without sampling controls).

# Returns
- `DataFrame`: One row per event with computed statistics
"""
function compute_statistics(seq::EventSequence{T}, stats::Vector{<:AbstractStatistic};
                            decay::Float64=0.0) where T
    state = NetworkState(seq; decay=decay)
    stat_names = [name(s) for s in stats]

    results = Vector{Vector{Float64}}()
    senders = Int[]
    receivers = Int[]
    times = T[]

    for (i, event) in enumerate(seq)
        # Update time and apply decay
        if decay > 0 && event.time > state.current_time
            apply_decay!(state, event.time)
        end
        state.current_time = event.time

        # Compute statistics
        stat_values = compute_all(stats, state, event.sender, event.receiver)
        push!(results, stat_values)
        push!(senders, event.sender)
        push!(receivers, event.receiver)
        push!(times, event.time)

        # Update state
        update!(state, event)
    end

    # Build DataFrame
    df = DataFrame(
        sender = senders,
        receiver = receivers,
        time = times
    )

    for (i, sname) in enumerate(stat_names)
        df[!, sname] = [r[i] for r in results]
    end

    return df
end
