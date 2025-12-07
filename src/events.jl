"""
Event loading and parsing utilities.
"""

"""
    load_events(filepath::String; kwargs...) -> EventSequence

Load events from a CSV file.

# Arguments
- `filepath`: Path to the CSV file

# Keyword Arguments
- `sender_col::Symbol=:sender`: Column name for sender IDs
- `receiver_col::Symbol=:receiver`: Column name for receiver IDs
- `time_col::Symbol=:time`: Column name for timestamps
- `type_col::Union{Symbol,Nothing}=nothing`: Column name for event types
- `weight_col::Union{Symbol,Nothing}=nothing`: Column name for event weights
- `time_type::Type=Float64`: Type to parse timestamps as
- `actor_names::Bool=false`: If true, treat sender/receiver as names and assign numeric IDs

# Returns
- `EventSequence`: Sequence of loaded events
"""
function load_events(filepath::String;
                     sender_col::Symbol=:sender,
                     receiver_col::Symbol=:receiver,
                     time_col::Symbol=:time,
                     type_col::Union{Symbol,Nothing}=nothing,
                     weight_col::Union{Symbol,Nothing}=nothing,
                     time_type::Type{T}=Float64,
                     actor_names::Bool=false) where T
    df = CSV.read(filepath, DataFrame)
    load_events(df; sender_col, receiver_col, time_col, type_col, weight_col,
                time_type, actor_names)
end

"""
    load_events(df::DataFrame; kwargs...) -> EventSequence

Load events from a DataFrame.
"""
function load_events(df::DataFrame;
                     sender_col::Symbol=:sender,
                     receiver_col::Symbol=:receiver,
                     time_col::Symbol=:time,
                     type_col::Union{Symbol,Nothing}=nothing,
                     weight_col::Union{Symbol,Nothing}=nothing,
                     time_type::Type{T}=Float64,
                     actor_names::Bool=false) where T
    # Build actor name mapping if needed
    name_to_id = Dict{Any, Int}()
    if actor_names
        all_actors = unique(vcat(df[!, sender_col], df[!, receiver_col]))
        for (i, name) in enumerate(all_actors)
            name_to_id[name] = i
        end
    end

    events = Event{T}[]
    sizehint!(events, nrow(df))

    for row in eachrow(df)
        # Get sender and receiver IDs
        if actor_names
            sender = name_to_id[row[sender_col]]
            receiver = name_to_id[row[receiver_col]]
        else
            sender = Int(row[sender_col])
            receiver = Int(row[receiver_col])
        end

        # Parse timestamp
        time_val = parse_time(row[time_col], T)

        # Get optional fields
        eventtype = isnothing(type_col) ? :event : Symbol(row[type_col])
        weight = isnothing(weight_col) ? 1.0 : Float64(row[weight_col])

        push!(events, Event(sender, receiver, time_val; eventtype, weight))
    end

    return EventSequence(events)
end

"""
    load_events!(seq::EventSequence, filepath::String; kwargs...)

Load events from a CSV file and add them to an existing EventSequence.
"""
function load_events!(seq::EventSequence{T}, filepath::String;
                      sender_col::Symbol=:sender,
                      receiver_col::Symbol=:receiver,
                      time_col::Symbol=:time,
                      type_col::Union{Symbol,Nothing}=nothing,
                      weight_col::Union{Symbol,Nothing}=nothing,
                      actor_names::Bool=false) where T
    df = CSV.read(filepath, DataFrame)
    load_events!(seq, df; sender_col, receiver_col, time_col, type_col,
                 weight_col, actor_names)
end

"""
    load_events!(seq::EventSequence, df::DataFrame; kwargs...)

Load events from a DataFrame and add them to an existing EventSequence.
"""
function load_events!(seq::EventSequence{T}, df::DataFrame;
                      sender_col::Symbol=:sender,
                      receiver_col::Symbol=:receiver,
                      time_col::Symbol=:time,
                      type_col::Union{Symbol,Nothing}=nothing,
                      weight_col::Union{Symbol,Nothing}=nothing,
                      actor_names::Bool=false,
                      name_to_id::Dict{Any,Int}=Dict{Any,Int}()) where T
    for row in eachrow(df)
        if actor_names
            sender = get!(name_to_id, row[sender_col], length(name_to_id) + 1)
            receiver = get!(name_to_id, row[receiver_col], length(name_to_id) + 1)
        else
            sender = Int(row[sender_col])
            receiver = Int(row[receiver_col])
        end

        time_val = parse_time(row[time_col], T)
        eventtype = isnothing(type_col) ? :event : Symbol(row[type_col])
        weight = isnothing(weight_col) ? 1.0 : Float64(row[weight_col])

        push!(seq, Event(sender, receiver, time_val; eventtype, weight))
    end

    return seq
end

"""
    parse_time(val, ::Type{T}) where T

Parse a time value to the specified type.
"""
parse_time(val::T, ::Type{T}) where T = val
parse_time(val::Number, ::Type{T}) where T<:Number = T(val)
parse_time(val::AbstractString, ::Type{Float64}) = parse(Float64, val)
parse_time(val::AbstractString, ::Type{Int}) = parse(Int, val)
parse_time(val::AbstractString, ::Type{DateTime}) = DateTime(val)
parse_time(val::AbstractString, ::Type{Date}) = Date(val)

# Handle Unix timestamps
function parse_time(val::Number, ::Type{DateTime})
    # Assume Unix timestamp in seconds
    DateTime(Dates.unix2datetime(val))
end

"""
    events_before(seq::EventSequence, idx::Int) -> view

Return a view of events occurring strictly before the event at index `idx`.
"""
function events_before(seq::EventSequence, idx::Int)
    return view(seq.events, 1:idx-1)
end

"""
    events_in_window(seq::EventSequence, idx::Int, window::Real) -> Vector{Event}

Return events occurring within `window` time units before the event at index `idx`.
"""
function events_in_window(seq::EventSequence{T}, idx::Int, window::Real) where T
    if idx <= 1
        return Event{T}[]
    end

    current_time = seq[idx].time
    start_time = current_time - window

    result = Event{T}[]
    for i in (idx-1):-1:1
        if seq[i].time >= start_time
            push!(result, seq[i])
        else
            break
        end
    end
    return result
end

"""
    halflife_to_decay(halflife::Real) -> Float64

Convert a halflife parameter to an exponential decay rate.
The decay rate λ is such that weight = exp(-λ * elapsed_time).
At time = halflife, the weight is 0.5.
"""
function halflife_to_decay(halflife::Real)
    halflife > 0 || throw(ArgumentError("halflife must be positive"))
    return log(2) / halflife
end

"""
    decay_to_halflife(decay::Real) -> Float64

Convert an exponential decay rate to a halflife parameter.
"""
function decay_to_halflife(decay::Real)
    decay > 0 || throw(ArgumentError("decay rate must be positive"))
    return log(2) / decay
end

"""
    compute_decay_weight(elapsed_time::Real, decay::Real) -> Float64

Compute the exponential decay weight for a given elapsed time.
"""
function compute_decay_weight(elapsed_time::Real, decay::Real)
    elapsed_time >= 0 || throw(ArgumentError("elapsed_time must be non-negative"))
    return exp(-decay * elapsed_time)
end
