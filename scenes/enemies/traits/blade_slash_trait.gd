class_name BladeSlashTrait
extends EnemyTrait
## Hovers, locks onto where you stand, then slashes through that spot at huge speed; several in a
## row strike one after another. Counter: move right after each lock flash, the slash hits where
## you were.

const STREAK := preload("res://assets/art/dusk_armada/enemies/blade_streak.gd")
const FLASH := Color(2.2, 2.2, 2.2)
const GLOW := Color(1.5, 1.1, 1.1)
const AFTER_SLASH := 0.25

@export var lock_time := 0.5
@export var slash_speed := 1000.0
@export var overshoot := 120.0

enum Phase { HOVER, LOCK, SLASH }


## The point a slash ends at: `overshoot` past the locked spot along the line from `from`.
static func slash_end(from: Vector2, locked: Vector2, past: float) -> Vector2:
	var direction := from.direction_to(locked)
	if direction == Vector2.ZERO:
		direction = Vector2.DOWN
	return locked + direction * past


func tick(enemy: Enemy, delta: float) -> void:
	var s := state(enemy)
	if enemy.state != Enemy.State.DIVING:
		_reset(enemy, s)
		return
	if not s.has("home"):
		s["home"] = enemy.position
		s["phase"] = Phase.HOVER
		s["t"] = 0.0
		s["wait"] = float(enemy.get_meta(&"slash_delay", 0.0))
	var t: float = s["t"] + delta
	s["t"] = t  # Phase changes reset it.
	enemy.velocity = Vector2.ZERO  # The brain steers; we own the position.
	match s["phase"]:
		Phase.HOVER:
			_hover(enemy, s, t)
		Phase.LOCK:
			_lock(enemy, s, t)
		Phase.SLASH:
			_slash(enemy, s, delta)


func killed(enemy: Enemy) -> void:
	_drop_sight(state(enemy))


func _hover(enemy: Enemy, s: Dictionary, t: float) -> void:
	var home: Vector2 = s["home"]
	enemy.position = home + Vector2(sin(t * 4.0) * 5.0, cos(t * 5.0) * 4.0)
	_face(enemy)
	var wait: float = s["wait"]
	enemy.modulate = Color.WHITE.lerp(GLOW, 0.5 + 0.5 * sin(t * 8.0)) if wait > 0.0 else Color.WHITE
	if t >= wait:
		_begin_lock(enemy, s)


func _begin_lock(enemy: Enemy, s: Dictionary) -> void:
	if not is_instance_valid(enemy.target):
		enemy.recall()
		return
	var locked := enemy.predicted_player(0.0)
	s["phase"] = Phase.LOCK
	s["locked"] = locked
	s["t"] = 0.0
	var sight := Node2D.new()
	sight.set_script(STREAK)
	sight.z_index = 40
	var parent: Node = enemy.entities if is_instance_valid(enemy.entities) else enemy.get_parent()
	parent.add_child(sight)
	s["sight"] = sight
	(sight as Node2D).call("set_line", enemy.position, locked)


func _lock(enemy: Enemy, s: Dictionary, t: float) -> void:
	enemy.modulate = FLASH if fmod(t, 0.1) < 0.06 else Color.WHITE
	enemy.rotation = (s["locked"] as Vector2 - enemy.position).angle() - PI / 2.0
	if t >= lock_time:
		var from := enemy.position
		var to := slash_end(from, s["locked"], overshoot)
		s["from"] = from
		s["to"] = to
		s["phase"] = Phase.SLASH
		enemy.modulate = Color.WHITE
		var sight := s.get("sight") as Node
		if is_instance_valid(sight):
			sight.call("set_line", from, to)
			sight.call("fade", 0.35)
		s.erase("sight")


func _slash(enemy: Enemy, s: Dictionary, delta: float) -> void:
	var to: Vector2 = s["to"]
	enemy.rotation = (to - enemy.position).angle() - PI / 2.0
	enemy.position = enemy.position.move_toward(to, slash_speed * delta)
	if enemy.position.distance_to(to) < 1.0:
		enemy.recall()  # Done: slotted blades fly home, released ones are freed.


func _face(enemy: Enemy) -> void:
	if is_instance_valid(enemy.target):
		enemy.rotation = (enemy.target.global_position - enemy.position).angle() - PI / 2.0


func _drop_sight(s: Dictionary) -> void:
	var sight := s.get("sight") as Node
	if is_instance_valid(sight):
		sight.queue_free()
	s.erase("sight")


func _reset(enemy: Enemy, s: Dictionary) -> void:
	if s.has("home"):
		_drop_sight(s)
		s.clear()
		enemy.modulate = Color.WHITE
