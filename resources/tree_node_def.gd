class_name TreeNodeDef
extends Resource
## A node on a ship's blueprint tree. It sits on a mount (or the hull) and opens only when the
## part fitted there is at least `min_tier` rare; swap in a lower-rarity part and the node goes
## dark until a rare enough part is back. Bought rank by rank with scrap.

@export var id: StringName
@export var display_name: String
## What one rank does.
@export var text: String
## nose, left, rear, right, or hull (no part needed).
@export var mount: StringName = &"hull"
@export var min_tier: PartDef.Tier = PartDef.Tier.STARTER
## Node that needs at least one rank first; empty for a root.
@export var requires: StringName
@export var max_rank := 1
## Scrap for rank 1; rank N costs N times this.
@export var cost := 100
## Applied once per rank (add: value x rank, mul: value ^ rank).
@export var effects: Array[Dictionary] = []
