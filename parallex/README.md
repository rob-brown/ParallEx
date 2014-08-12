# Parallex

## Summary

`ParallEx` is a group of common parallel collections. The intent is to make it easy to process large amounts of data. 

## Goals

1 Create immutable parallel collections for Elixir. 
2 Conform to the existing Enum protocol.
3 Vastly improve the performance over sequential collections.
4 Make the collections extensible.
5 Easy conversions between sequential and parallel counterparts.

The initial design of `ParallEx` is largely influenced by the design of Scala's parallel collections. `ParallEx` also references [A Generic Parallel Collection Framework by Aleksandar Prokopec, Tiark Rompf, Phil Bagwell, and Martin Odersky](http://infoscience.epfl.ch/record/150220/files/pc.pdf)
