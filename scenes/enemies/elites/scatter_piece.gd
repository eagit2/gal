class_name ScatterPiece
extends Node2D
## One block of the Scatter Titan. Rests in the body, flies a straight line across the screen when
## the Titan breaks apart (hurting on contact, not destroyable), then flies back to rebuild.
## The trait drives it with `fly_out` and `fly_back`.

enum Mode { HOME, OUT, GONE, BACK }

const BOUNDS := Rect2(-40.0, -40.0, 620.0, 1040.0)

var mode := Mode.HOME
var home := Vector2.ZERO
var direction := Vector2.DOWN

@onready var _hitbox: Hitbox = $Hitbox
@onready var _visual: Node2D = $Visual


func set_mode(new_mode: Mode) -> void:
	mode = new_mode
	_hitbox.set_deferred(&"monitoring", mode == Mode.OUT or mode == Mode.BACK)
	visible = mode != Mode.GONE


func set_flash(on: bool) -> void:
	_visual.call("set_flash", on)


## Moves along `direction`; true once it has left the screen.
func fly_out(delta: float, speed: float) -> bool:
	position += direction * speed * delta
	return not BOUNDS.has_point(position)


## Moves toward `goal`; true once it has arrived.
func fly_back(delta: float, speed: float, goal: Vector2) -> bool:
	var step := speed * delta
	if position.distance_to(goal) <= step:
		position = goal
		return true
	position += position.direction_to(goal) * step
	return false
