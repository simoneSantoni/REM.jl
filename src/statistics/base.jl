"""
Base types and interface for REM statistics.
"""

"""
    AbstractStatistic

Abstract base type for all REM statistics.

All statistics must implement:
- `compute(stat::AbstractStatistic, state::NetworkState, sender::Int, receiver::Int) -> Float64`
- `name(stat::AbstractStatistic) -> String`
"""
abstract type AbstractStatistic end

"""
    DyadStatistic <: AbstractStatistic

Statistics that depend on the history of events between the focal dyad (sender, receiver).
Examples: repetition, reciprocity, inertia.
"""
abstract type DyadStatistic <: AbstractStatistic end

"""
    DegreeStatistic <: AbstractStatistic

Statistics that depend on the degree (activity/popularity) of actors.
Examples: sender activity, receiver popularity.
"""
abstract type DegreeStatistic <: AbstractStatistic end

"""
    TriangleStatistic <: AbstractStatistic

Statistics that measure triadic closure effects.
Examples: transitive closure, cyclic closure, shared partners.
"""
abstract type TriangleStatistic <: AbstractStatistic end

"""
    FourCycleStatistic <: AbstractStatistic

Statistics that measure four-cycle (local clustering) effects.
"""
abstract type FourCycleStatistic <: AbstractStatistic end

"""
    NodeStatistic <: AbstractStatistic

Statistics based on node-level attributes.
Examples: homophily, attribute matching.
"""
abstract type NodeStatistic <: AbstractStatistic end

"""
    InteractionStatistic <: AbstractStatistic

Statistics that capture interaction effects between attributes.
"""
abstract type InteractionStatistic <: AbstractStatistic end

"""
    compute(stat::AbstractStatistic, state::NetworkState, sender::Int, receiver::Int) -> Float64

Compute the statistic value for a potential event from sender to receiver.
This is the main interface that all statistics must implement.
"""
function compute(stat::AbstractStatistic, state::NetworkState, sender::Int, receiver::Int)
    error("compute() not implemented for $(typeof(stat))")
end

"""
    name(stat::AbstractStatistic) -> String

Return a descriptive name for the statistic.
"""
function name(stat::AbstractStatistic)
    return string(typeof(stat))
end

"""
    StatisticSet

A collection of statistics to compute together.
"""
struct StatisticSet
    statistics::Vector{AbstractStatistic}
    names::Vector{String}

    function StatisticSet(stats::Vector{<:AbstractStatistic})
        names = [name(s) for s in stats]
        new(stats, names)
    end
end

Base.length(ss::StatisticSet) = length(ss.statistics)
Base.iterate(ss::StatisticSet, state=1) = state > length(ss) ? nothing : (ss.statistics[state], state + 1)
Base.getindex(ss::StatisticSet, i) = ss.statistics[i]

"""
    compute_all(ss::StatisticSet, state::NetworkState, sender::Int, receiver::Int) -> Vector{Float64}

Compute all statistics in the set for a potential event.
"""
function compute_all(ss::StatisticSet, state::NetworkState, sender::Int, receiver::Int)
    return [compute(s, state, sender, receiver) for s in ss.statistics]
end

"""
    compute_all(stats::Vector{<:AbstractStatistic}, state::NetworkState, sender::Int, receiver::Int) -> Vector{Float64}

Compute all statistics for a potential event.
"""
function compute_all(stats::Vector{<:AbstractStatistic}, state::NetworkState, sender::Int, receiver::Int)
    return [compute(s, state, sender, receiver) for s in stats]
end
