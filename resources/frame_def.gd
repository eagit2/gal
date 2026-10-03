class_name FrameDef
extends Resource
## A ship frame: how many module slots it has and which are linked in pairs, plus its own
## effects and hull palette.

## Slot anchors on the 1x player sprite, relative to its center. Slots fill in this order.
const ANCHORS: Array[Vector2] = [Vector2(-9, 2), Vector2(9, 2), Vector2(0, -10), Vector2(0, 10), Vector2(-4, -3), Vector2(4, -3)]

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var cost: int = 0
@export_range(1, 6) var slots: int = 3
## The first `pairs * 2` slots are linked two by two (0-1, 2-3, 4-5).
@export var pairs: int = 1
@export var effects: Array[Dictionary] = []
## Player sprite for this frame (assets/art/dusk_armada/player_<id>.png).
@export var sprite: Texture2D


func partner(slot: int) -> int:
	if slot >= pairs * 2:
		return -1
	return slot + 1 if slot % 2 == 0 else slot - 1
