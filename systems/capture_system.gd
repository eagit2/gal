class_name CaptureSystem
extends Node
## Galaga's capture and dual fighter. Now and then a capture-capable enemy (EnemyDef.can_capture)
## leaves formation on a tractor-beam run (CaptureBrain). A captured ship costs a life and rides
## above its captor. Destroying the captor while it is attacking frees the ship, which docks beside
## the player as a wingman (double fire, an extra hit). Destroying it in formation loses the ship.

const CAPTURE_BRAIN := preload("res://data/brains/capture.tres")
const CAPTIVE_OFFSET := Vector2(0, -34)
const CAPTIVE_TINT := Color(1.0, 0.45, 0.45)
const DOCK_TIME := 0.9
## Seconds between the captor's attack runs while it holds a captured ship.
const RESCUE_CHANCE_EVERY := Vector2(6.0, 10.0)

## Captures only happen while the dive controller is attacking (not on challenge stages).
var dives: DiveController
var player: Player
## Seconds between capture attempts; dev runs can shorten it (DevOptions `capture=1`).
var first_delay := 12.0
var interval := Vector2(16.0, 24.0)
var captor: Enemy
var _timer := 0.0


func _ready() -> void:
	EventBus.stage_started.connect(func(_id: StringName) -> void: _timer = first_delay)
	EventBus.player_captured.connect(_on_player_captured)
	EventBus.enemy_killed.connect(_on_enemy_killed)


func _physics_process(delta: float) -> void:
	if not dives.active or GameState.freeze_left > 0.0:
		return
	_timer -= delta
	if is_instance_valid(captor):
		# The captor attacks often while it holds the ship, so the player gets rescue chances.
		if _timer <= 0.0 and player.alive and captor.state == Enemy.State.IN_FORMATION:
			_timer = randf_range(RESCUE_CHANCE_EVERY.x, RESCUE_CHANCE_EVERY.y)
			captor.start_attack(player, 1.0)
		return
	if _timer > 0.0:
		return
	_timer = randf_range(interval.x, interval.y)
	if player.alive and not player.dual:
		var candidate := _idle_capturer()
		if candidate:
			candidate.start_attack(player, 1.0, CAPTURE_BRAIN)


func _idle_capturer() -> Enemy:
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy.def.can_capture and enemy.state == Enemy.State.IN_FORMATION:
			return enemy
	return null


func _on_player_captured(enemy: Node2D) -> void:
	captor = enemy as Enemy
	_timer = RESCUE_CHANCE_EVERY.y
	var captive := player.make_ship_copy()
	captive.modulate = CAPTIVE_TINT
	captive.position = CAPTIVE_OFFSET
	captive.rotation = PI
	captive.name = "Captive"
	captor.add_child(captive)


func _on_enemy_killed(node: Node2D, at: Vector2, _score: int) -> void:
	if node != captor:
		return
	captor = null
	_timer = randf_range(interval.x, interval.y)
	if (node as Enemy).state != Enemy.State.DIVING:
		EventBus.captive_lost.emit()
		return
	# Freed: the ship flies down and docks beside the player.
	var ship := player.make_ship_copy()
	ship.global_position = at + CAPTIVE_OFFSET
	get_parent().add_child(ship)
	var tween := ship.create_tween()
	tween.tween_property(ship, "global_position", player.global_position + Player.WINGMAN_OFFSET, DOCK_TIME)
	tween.tween_callback(func() -> void:
		ship.queue_free()
		player.set_dual(true)
		EventBus.ship_rescued.emit())
