class_name FireBarTrait
extends EnemyTrait
## While diving it breathes a spinning, meandering chain of fireballs that hurts on contact and
## reverses now and then. Counter: slip through the gap as the bar swings past, or shoot the breather.

@export var bar_scene: PackedScene = preload("res://scenes/enemies/traits/fire_bar.tscn")
@export var segments := 6
@export var spacing := 18.0
@export var spin_speed := 1.6
@export var wobble := 24.0
@export var wobble_speed := 3.0
@export var reverse_every := 5.0


func tick(enemy: Enemy, _delta: float) -> void:
	var held: Variant = state(enemy).get("bar")
	var bar: FireBar = held if is_instance_valid(held) else null
	var diving := enemy.state == Enemy.State.DIVING
	if diving and bar == null:
		bar = bar_scene.instantiate()
		bar.segments = segments
		bar.spacing = spacing
		bar.spin_speed = spin_speed
		bar.wobble = wobble
		bar.wobble_speed = wobble_speed
		bar.reverse_every = reverse_every
		enemy.add_child(bar)
		bar.setup(enemy)
		state(enemy)["bar"] = bar
	elif not diving and bar != null:
		bar.queue_free()
		state(enemy).erase("bar")


func killed(enemy: Enemy) -> void:
	var held: Variant = state(enemy).get("bar")
	if is_instance_valid(held):
		(held as FireBar).queue_free()
