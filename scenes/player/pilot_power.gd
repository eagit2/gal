extends Node
## Runs the hangar pilot's active power. It fires on its own when the moment fits the power
## (controls are only steering and firing), then recharges over the pilot's cooldown.
## Starts each life fully charged.

## Seconds a dash takes to cover its distance.
const DASH_TIME := 0.12
## Bulwark and Phase Dash fire when an enemy or enemy shot gets this close.
const CLOSE_RADIUS := 60.0
## Nova fires when this many threats are within NOVA_RADIUS.
const NOVA_COUNT := 6
const NOVA_RADIUS := 170.0
## Overclock fires only once this many enemies are diving at once (never just because a stage started).
const OVERCLOCK_DIVERS := 3

var player: Player
var _pilot: PilotDef
var _charge := 1.0
var _active := 0.0
var _dash := Vector2.ZERO
var _dash_left := 0.0
var _reported := -1


func _ready() -> void:
	_pilot = Hangar.pilot()
	_report()


func _exit_tree() -> void:
	Hangar.set_power_effects([])


func _physics_process(delta: float) -> void:
	var real_delta := delta / Engine.time_scale
	if _dash_left > 0.0:
		var step := minf(real_delta, _dash_left)
		_dash_left -= step
		player.position = (player.position + _dash * step / DASH_TIME).clamp(Vector2(Player.MARGIN, Player.MIN_Y), Vector2(540 - Player.MARGIN, Player.MAX_Y))
	if _active > 0.0:
		_active -= real_delta
		if _active <= 0.0 and not _pilot.effects.is_empty():
			Hangar.set_power_effects([])
	if _charge < 1.0:
		_charge = minf(_charge + real_delta / _pilot.cooldown, 1.0)
		_report()
	if _charge >= 1.0 and _wanted():
		use()


## Whether now is a good moment for this pilot's power.
func _wanted() -> bool:
	var tree := get_tree()
	var pos := player.global_position
	match _pilot.power:
		PilotDef.Power.OVERCLOCK:
			return tree.get_nodes_in_group(&"attackers").size() >= OVERCLOCK_DIVERS
		PilotDef.Power.BULWARK, PilotDef.Power.PHASE_DASH:
			return Threat.count(tree, pos, CLOSE_RADIUS) > 0
		PilotDef.Power.NOVA:
			return Threat.count(tree, pos, NOVA_RADIUS) >= NOVA_COUNT
	return false


## Fires the power if it is charged and the ship is flying. Returns true when it fired.
func use() -> bool:
	if _charge < 1.0 or not player.alive or get_tree().paused:
		return false
	_charge = 0.0
	_report()
	match _pilot.power:
		PilotDef.Power.OVERCLOCK:
			Hangar.set_power_effects(_pilot.effects)
		PilotDef.Power.BULWARK:
			player.shield.restore()
			player.grant_invulnerability(_pilot.duration)
		PilotDef.Power.PHASE_DASH:
			var direction := Threat.away(get_tree(), player.global_position, CLOSE_RADIUS * 2.0)
			if direction == Vector2.ZERO:
				direction = player.velocity.normalized() if player.velocity.length() > 10.0 else Vector2.UP
			_dash = direction.normalized() * _pilot.distance
			_dash_left = DASH_TIME
			player.grant_invulnerability(_pilot.duration)
		PilotDef.Power.NOVA:
			_nova()
	_active = _pilot.duration
	EventBus.power_used.emit(_pilot)
	return true


func _nova() -> void:
	for node in get_tree().get_nodes_in_group(&"enemy_shots"):
		(node as Bullet).release()
	for node in get_tree().get_nodes_in_group(&"enemies") + get_tree().get_nodes_in_group(&"elites"):
		node.call("damage", _pilot.damage)


func _report() -> void:
	var step := floori(_charge * 10.0)
	if step != _reported:
		_reported = step
		EventBus.power_changed.emit(_charge)
