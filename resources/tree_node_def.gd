class_name TreeNodeDef
extends Resource
## A node on a ship's skill tree. Nodes sit in branches (offense, defense, utility); each needs a
## rank in the node above it. Bought rank by rank with scrap; the effects belong to the ship, not
## to any part.

@export var id: StringName
@export var display_name: String
## What one rank does.
@export var text: String
## offense, defense or utility (a column in the tree).
@export var branch: StringName = &"offense"
## Node that needs at least one rank first; empty for the top of a branch.
@export var requires: StringName
@export var max_rank := 1
## Scrap for rank 1; rank N costs N times this.
@export var cost := 100
## Applied once per rank (add: value x rank, mul: value ^ rank).
@export var effects: Array[Dictionary] = []
