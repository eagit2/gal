class_name ScrapThiefTrait
extends EnemyTrait
## While diving it snatches falling scrap piles, then flees upward off the screen with them. Kill
## it to get everything back with interest. Counter: chase it down before it leaves the screen.

@export var grab_radius := 60.0
@export var flee_speed := 300.0
@export var max_carry := 20
@export var payback := 1.5

const LOOT_GLOW := Color(1.6, 1.4, 0.6)
const SCAN_GAP := 0.1


## Scrap dropped when a thief carrying `carried` dies.
static func payout(carried: int, interest: float) -> int:
	return roundi(carried * interest)


## How much of a pile of `pile` a thief already holding `held` can take.
static func take_amount(pile: int, held: int, cap: int) -> int:
	return clampi(cap - held, 0, pile)


func tick(enemy: Enemy, delta: float) -> void:
	var s := state(enemy)
	if s.get("fleeing", false):
		_flee(enemy, delta)
		return
	if enemy.state != Enemy.State.DIVING:
		return
	var wait: float = s.get("scan", 0.0) - delta
	if wait > 0.0:
		s["scan"] = wait
		return
	s["scan"] = SCAN_GAP
	var held: int = s.get("carried", 0)
	for node in enemy.entities.get_children():
		var pile := node as Pickup
		if pile == null or pile.is_queued_for_deletion() or held >= max_carry:
			continue
		if pile.global_position.distance_to(enemy.global_position) > grab_radius:
			continue
		var took := take_amount(pile.amount, held, max_carry)
		held += took
		pile.amount -= took
		if pile.amount <= 0:
			pile.queue_free()
	if held > s.get("carried", 0):
		s["carried"] = held
		s["fleeing"] = true
		s["last"] = enemy.position
		enemy.modulate = LOOT_GLOW
		enemy.aim_facing = false


func killed(enemy: Enemy) -> void:
	var carried: int = state(enemy).get("carried", 0)
	if carried > 0:
		EventBus.scrap_dropped.emit(enemy.global_position, payout(carried, payback))


## Overrides the brain's movement: straight up, a little away from the player.
func _flee(enemy: Enemy, delta: float) -> void:
	var s := state(enemy)
	var last: Vector2 = s["last"]
	enemy.rotation = lerp_angle(enemy.rotation, PI, minf(1.0, 8.0 * delta))
	var away := 0.0
	if is_instance_valid(enemy.target):
		away = signf(enemy.position.x - enemy.target.global_position.x) * 0.25
	enemy.velocity = Vector2(away, -1.0) * flee_speed
	enemy.position = last + enemy.velocity * delta
	enemy.position.x = clampf(enemy.position.x, Enemy.MIN_X, Enemy.MAX_X)
	s["last"] = enemy.position
	if enemy.position.y < Enemy.TOP:
		enemy.remove_from_group(&"enemies")
		enemy.remove_from_group(&"attackers")
		EventBus.enemy_escaped.emit(enemy)
		enemy.queue_free()
