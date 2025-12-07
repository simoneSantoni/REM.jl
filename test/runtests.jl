using REM
using Test
using DataFrames
using Dates

@testset "REM.jl" begin
    @testset "Event and EventSequence" begin
        # Test Event creation
        e1 = Event(1, 2, 1.0)
        @test e1.sender == 1
        @test e1.receiver == 2
        @test e1.time == 1.0
        @test e1.eventtype == :event
        @test e1.weight == 1.0

        e2 = Event(2, 3, 2.0; eventtype=:email, weight=2.0)
        @test e2.eventtype == :email
        @test e2.weight == 2.0

        # Test EventSequence
        events = [
            Event(1, 2, 1.0),
            Event(2, 1, 2.0),
            Event(1, 3, 3.0),
            Event(3, 2, 4.0)
        ]
        seq = EventSequence(events)

        @test length(seq) == 4
        @test seq.n_actors == 3
        @test Set([1, 2, 3]) == seq.actors

        # Test iteration
        times = [e.time for e in seq]
        @test times == [1.0, 2.0, 3.0, 4.0]

        # Test push! maintains sorted order
        push!(seq, Event(2, 3, 2.5))
        @test length(seq) == 5
        @test seq[3].time == 2.5
    end

    @testset "Data Loading" begin
        # Create test DataFrame
        df = DataFrame(
            sender = [1, 2, 1, 3],
            receiver = [2, 1, 3, 2],
            time = [1.0, 2.0, 3.0, 4.0]
        )

        seq = load_events(df)
        @test length(seq) == 4
        @test seq.n_actors == 3

        # Test with string actor names
        df_names = DataFrame(
            sender = ["Alice", "Bob", "Alice", "Carol"],
            receiver = ["Bob", "Alice", "Carol", "Bob"],
            time = [1.0, 2.0, 3.0, 4.0]
        )

        seq_names = load_events(df_names; actor_names=true)
        @test length(seq_names) == 4
        @test seq_names.n_actors == 3
    end

    @testset "NetworkState" begin
        events = [
            Event(1, 2, 1.0),
            Event(2, 1, 2.0),
            Event(1, 2, 3.0),
            Event(1, 3, 4.0)
        ]
        seq = EventSequence(events)
        state = NetworkState(seq)

        # Process events
        for e in seq
            update!(state, e)
        end

        @test get_dyad_count(state, 1, 2) == 2.0
        @test get_dyad_count(state, 2, 1) == 1.0
        @test get_dyad_count(state, 1, 3) == 1.0
        @test get_dyad_count(state, 3, 1) == 0.0

        @test get_out_degree(state, 1) == 3.0
        @test get_in_degree(state, 2) == 2.0

        @test has_edge(state, 1, 2)
        @test !has_edge(state, 3, 1)
    end

    @testset "Calendar timelines" begin
        # Decay with DateTime timestamps (1 hour halflife)
        dt_events = [
            Event(1, 2, DateTime(2024, 1, 1, 0, 0, 0)),
            Event(1, 2, DateTime(2024, 1, 1, 1, 0, 0))
        ]
        seq_dt = EventSequence(dt_events)
        state_dt = NetworkState(seq_dt; decay=halflife_to_decay(3600.0))

        update!(state_dt, seq_dt[1])
        update!(state_dt, seq_dt[2])
        @test get_dyad_count(state_dt, 1, 2) ≈ 1.5 atol=1e-8

        # Recency with Date timestamps (difference in seconds)
        date_events = [
            Event(1, 2, Date(2024, 1, 1)),
            Event(2, 1, Date(2024, 1, 2))
        ]
        seq_date = EventSequence(date_events)
        state_date = NetworkState(seq_date)
        update!(state_date, seq_date[1])
        update!(state_date, seq_date[2])
        state_date.current_time = Date(2024, 1, 3)

        recency = RecencyStatistic()
        @test compute(recency, state_date, 1, 2) ≈ 1 / (2 * 86400) atol=1e-12
    end

    @testset "Dyad Statistics" begin
        events = [
            Event(1, 2, 1.0),
            Event(2, 1, 2.0),
            Event(1, 2, 3.0)
        ]
        seq = EventSequence(events)
        state = NetworkState(seq)

        # Process first two events
        update!(state, seq[1])
        update!(state, seq[2])
        state.current_time = seq[3].time

        # Test Repetition
        rep = Repetition()
        @test compute(rep, state, 1, 2) == 1.0  # 1→2 happened once
        @test compute(rep, state, 2, 1) == 1.0  # 2→1 happened once
        @test compute(rep, state, 1, 3) == 0.0  # 1→3 never happened

        # Test undirected repetition
        rep_undir = Repetition(directed=false)
        @test compute(rep_undir, state, 1, 2) == 2.0  # 1↔2 has 2 events

        # Test Reciprocity
        recip = Reciprocity()
        @test compute(recip, state, 1, 2) == 1.0  # 2→1 exists
        @test compute(recip, state, 2, 1) == 1.0  # 1→2 exists
        @test compute(recip, state, 1, 3) == 0.0  # 3→1 doesn't exist
    end

    @testset "Degree Statistics" begin
        events = [
            Event(1, 2, 1.0),
            Event(1, 3, 2.0),
            Event(2, 3, 3.0)
        ]
        seq = EventSequence(events)
        state = NetworkState(seq)

        for e in seq
            update!(state, e)
        end

        # Test sender activity
        sa = SenderActivity()
        @test compute(sa, state, 1, 4) == 2.0  # Actor 1 sent 2 events
        @test compute(sa, state, 2, 4) == 1.0  # Actor 2 sent 1 event

        # Test receiver popularity
        rp = ReceiverPopularity()
        @test compute(rp, state, 4, 3) == 2.0  # Actor 3 received 2 events
        @test compute(rp, state, 4, 2) == 1.0  # Actor 2 received 1 event
    end

    @testset "Triangle Statistics" begin
        # Create a network: 1→2, 2→3
        events = [
            Event(1, 2, 1.0),
            Event(2, 3, 2.0)
        ]
        seq = EventSequence(events)
        state = NetworkState(seq)

        for e in seq
            update!(state, e)
        end

        # Test transitive closure
        # For 1→3: we need k such that 1→k and k→3
        # 1→2 exists, 2→3 exists, so k=2 works
        tc = TransitiveClosure()
        @test compute(tc, state, 1, 3) == 1.0

        # For 3→1: need k such that 3→k and k→1 - doesn't exist
        @test compute(tc, state, 3, 1) == 0.0
    end

    @testset "Node Statistics" begin
        # Create node attribute
        gender = NodeAttribute(:gender, Dict(1 => "M", 2 => "M", 3 => "F"), "Unknown")

        # Test NodeMatch
        match = NodeMatch(gender)
        state = NetworkState{Float64}()
        @test compute(match, state, 1, 2) == 1.0  # Both M
        @test compute(match, state, 1, 3) == 0.0  # M vs F

        # Test numeric attribute
        age = NodeAttribute(:age, Dict(1 => 25.0, 2 => 30.0, 3 => 25.0), 0.0)
        diff = NodeDifference(age)
        @test compute(diff, state, 1, 2) == -5.0  # 25 - 30
        @test compute(diff, state, 2, 1) == 5.0   # 30 - 25

        diff_abs = NodeDifference(age; absolute=true)
        @test compute(diff_abs, state, 1, 2) == 5.0
    end

    @testset "Case-Control Sampling" begin
        events = [
            Event(1, 2, 1.0),
            Event(2, 1, 2.0),
            Event(1, 3, 3.0),
            Event(3, 2, 4.0)
        ]
        seq = EventSequence(events)

        stats = [Repetition(), Reciprocity()]
        sampler = CaseControlSampler(n_controls=5, seed=42)

        obs = generate_observations(seq, stats, sampler)

        # Should have 4 cases + 4*5 controls = 24 observations
        @test nrow(obs) == 24

        # Check columns exist
        @test "is_event" in names(obs)
        @test "stratum" in names(obs)
        @test "repetition" in names(obs)
        @test "reciprocity" in names(obs)

        # Check we have correct number of cases
        @test sum(obs.is_event) == 4
    end

    @testset "Utility Functions" begin
        # Test halflife conversion
        halflife = 10.0
        decay = halflife_to_decay(halflife)
        @test decay ≈ log(2) / 10.0

        # Round-trip
        @test decay_to_halflife(decay) ≈ halflife
    end

    @testset "Integration Test" begin
        # Full pipeline test
        events = [
            Event(1, 2, 1.0),
            Event(2, 1, 2.0),
            Event(1, 2, 3.0),
            Event(2, 3, 4.0),
            Event(3, 1, 5.0),
            Event(1, 3, 6.0)
        ]
        seq = EventSequence(events)

        stats = [
            Repetition(),
            Reciprocity(),
            SenderActivity(),
            ReceiverPopularity()
        ]

        # Generate observations
        sampler = CaseControlSampler(n_controls=10, seed=123)
        obs = generate_observations(seq, stats, sampler)

        @test nrow(obs) == 6 * 11  # 6 events * (1 case + 10 controls)

        # Compute statistics without sampling
        stats_df = compute_statistics(seq, stats)
        @test nrow(stats_df) == 6
    end
end
