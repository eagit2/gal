class_name TreeNodeDef
extends Resource
## A node on a ship's skill tree. Nodes need ranks in the nodes they hang from (`requires`); a merge
## node needs all of them, a capstone any `needs` of them. Fork nodes name their partner in
## `excludes`: buying one closes the other. Bought rank by rank with scrap; the effects belong to
## the ship, not to any part.

@export var id: StringName
@export var display_name: String
## What one rank does.
@export var text: String
## offense, defense, utility, or merge (a node where branches meet).
@export var branch: StringName = &"offense"
## Nodes that need a rank first; empty for a first-row node.
@export var requires: Array[StringName] = []
## How many of `requires` are needed; 0 = all of them.
@export var needs := 0
## The other side of a fork: owning either closes the other.
@export var excludes: StringName
@export var max_rank := 1
## Scrap for rank 1; rank N costs N times this.
@export var cost := 100
## Applied once per rank (add: value x rank, mul: value ^ rank).
@export var effects: Array[Dictionary] = []
## Extra link sockets, per rank, on every part of this category (PartDef.Category; -1 = none).
@export var socket_category := -1
## Where it sits on the tree screen: row 0 is the bottom, column 0-5 left to right (halves allowed).
@export var row := 0
@export var column := 0.0
