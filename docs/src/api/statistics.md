# Statistics API Reference

## Base Types and Interface

```@docs
AbstractStatistic
DyadStatistic
DegreeStatistic
TriangleStatistic
FourCycleStatistic
NodeStatistic
InteractionStatistic
compute
name
StatisticSet
compute_all
```

## Dyad Statistics

```@docs
Repetition
Reciprocity
InertiaStatistic
RecencyStatistic
DyadCovariate
```

## Degree Statistics

```@docs
SenderActivity
ReceiverActivity
SenderPopularity
ReceiverPopularity
TotalDegree
DegreeDifference
LogDegree
```

## Triangle Statistics

```@docs
TransitiveClosure
CyclicClosure
SharedSender
SharedReceiver
CommonNeighbors
GeometricWeightedTriads
```

## Four-Cycle Statistics

```@docs
FourCycle
GeometricWeightedFourCycles
```

## Node Attribute Statistics

```@docs
NodeMatch
NodeMix
NodeDifference
NodeSum
NodeProduct
SenderAttribute
ReceiverAttribute
SenderCategorical
ReceiverCategorical
```
