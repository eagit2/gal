class_name LeafNode
extends Node2D
## One leaf of the Leaf Warden. Guarding, its hurtbox soaks up the player's shots; launched, it
## flies straight and hurts on contact. The trait drives it.

enum Mode { GUARD, FLY, GONE, GROW }

const BOUNDS := Rect2(-40.0, -40.0, 620.0, 1040.0)

var mode := Mode.GONE
var velocity := Vector2.ZERO

@onready var _block: Hurtbox = $Hurtbox
@onready var _hitbox: Hitbox = $Hitbox
@onready var _visual: Node2D = $Visual


func set_mode(new_mode: Mode) -> void:
	mode = new_mode
	_block.set_deferred(&"monitorable", mode == Mode.GUARD or mode == Mode.FLY)
	_hitbox.set_deferred(&"monitoring", mode == Mode.GUARD or mode == Mode.FLY)
	visible = mode != Mode.GONE
	if mode != Mode.FLY and mode != Mode.GROW:
		scale = Vector2.ONE


func set_warn(on: bool) -> void:
	_visual.call("set_warn", on)


## Grows from nothing; `fraction` 0..1.
func set_growth(fraction: float) -> void:
	scale = Vector2.ONE * clampf(fraction, 0.05, 1.0)


## Moves along its launch velocity; true once off screen.
func fly(delta: float) -> bool:
	position += velocity * delta
	rotation = velocity.angle() + PI / 2
	return not BOUNDS.has_point(position)
