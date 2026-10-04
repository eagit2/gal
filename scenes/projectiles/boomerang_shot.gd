class_name BoomerangShot
extends Bullet
## Enemy shot that curves out for `reach` pixels, then flies back to where it was thrown from.
## Hurts the player like an ordinary enemy bullet.

const ARRIVE := 18.0
const HOMING_TURN := 7.0

var _origin := Vector2.ZERO
var _reach := 220.0
var _return_speed := 320.0
var _curve := 2.0
var _returning := false


## Starts a throw from the current position: the launch velocity is the outbound velocity and
## `curve` the turn in radians per second.
func throw(reach: float, return_speed: float, curve: float) -> void:
	_origin = global_position
	_reach = reach
	_return_speed = return_speed
	_curve = curve
	_returning = false


## Turn rate (radians per second) that bends the outbound leg through `sweep` radians in total.
static func curve_rate(reach: float, speed: float, sweep: float) -> float:
	return sweep * speed / maxf(reach, 1.0)


func _physics_process(delta: float) -> void:
	if GameState.freeze_left > 0.0:
		return
	if _returning:
		var to_origin := _origin - position
		if to_origin.length() <= ARRIVE:
			release()
			return
		velocity = Steering.turn(velocity, to_origin, HOMING_TURN * delta, _return_speed)
	else:
		velocity = velocity.rotated(_curve * delta)
		_travelled += velocity.length() * delta
		if _travelled >= _reach:
			_returning = true
	position += velocity * delta
	if _active and not BOUNDS.has_point(position):
		release()
