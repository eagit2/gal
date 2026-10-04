class_name EvolveTrait
extends EnemyTrait
## After living `evolve_time` seconds it glows, then upgrades into a tougher type (bee to moth).
## Counter: kill it before the glow finishes.

@export var into: EnemyDef = preload("res://data/enemies/moth.tres")
@export var evolve_time := 8.0
@export var warn_time := 1.5

const GLOW := Color(2.0, 1.8, 0.9)


## 0 until the glow starts, rising to 1 when the enemy evolves.
static func glow_fraction(age: float, delay: float, warn: float) -> float:
	if age < delay:
		return 0.0
	return clampf((age - delay) / maxf(warn, 0.001), 0.0, 1.0)


func tick(enemy: Enemy, delta: float) -> void:
	var s := state(enemy)
	var age: float = s.get("age", 0.0) + delta
	s["age"] = age
	var f := glow_fraction(age, evolve_time, warn_time)
	if f <= 0.0:
		return
	if f < 1.0:
		var pulse := 0.5 + 0.5 * sin(age * lerpf(10.0, 30.0, f))
		enemy.modulate = Color.WHITE.lerp(GLOW, pulse * f)
		return
	_evolve(enemy)


func _evolve(enemy: Enemy) -> void:
	enemy.modulate = Color.WHITE
	var old: Node = enemy.get_node_or_null("Visual")
	if old:
		old.queue_free()
		old.name = "OldVisual"
	enemy.def = into
	var visual: Node2D = into.visual_scene.instantiate()
	visual.name = "Visual"
	visual.scale *= into.visual_scale
	visual.modulate *= into.tint
	enemy.add_child(visual)
	enemy.set("_visual", visual)
	enemy.set("_tint", visual.modulate)
	var hp := maxi(1, roundi(into.hp * enemy.difficulty.enemy_hp * enemy.hp_scale))
	enemy.health().reset(hp)
	enemy.trait_state.erase(self)
	for t in into.all_traits():
		t.begin(enemy)
	# Pop and flash so the change reads.
	visual.scale *= 1.6
	visual.modulate = Color(3, 3, 3)
	var tween := visual.create_tween().set_parallel()
	tween.tween_property(visual, "scale", visual.scale / 1.6, 0.3)
	tween.tween_property(visual, "modulate", enemy.get("_tint"), 0.3)
