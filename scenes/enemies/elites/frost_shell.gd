class_name FrostShellTrait
extends EliteTrait
## Wrapped in layers of ice that soak every hit. Heavy or piercing shots crack the ice faster, and
## the shell regrows a layer at a time when the player stops shooting it. While shelled it sheds
## rings of slow ice shards.
## Counter: keep the pressure on (or bring heavy/piercing guns), and weave through the rings.

@export var layers := 3
@export var layer_hp := 10
## Damage multiplier on ice for shots with damage >= 2 or pierce.
@export var heavy_mult := 3
@export var regrow_delay := 2.5
@export var regrow_interval := 1.2
@export var ring_interval := 4.5
@export var ring_shards := 12
@export var ring_speed := 110.0
@export var shell_visual: PackedScene


func begin(elite: Elite) -> void:
	elite.state["layers"] = layers
	elite.state["ice"] = layer_hp
	elite.state["since_hit"] = 0.0
	elite.state["ring"] = ring_interval
	var visual: Node2D = shell_visual.instantiate()
	elite.add_child(visual)
	elite.state["visual"] = visual
	_show(elite)


func tick(elite: Elite, delta: float) -> void:
	elite.state["since_hit"] += delta
	if elite.state["layers"] < layers and elite.state["since_hit"] >= regrow_delay:
		elite.state["layers"] += 1
		elite.state["ice"] = layer_hp
		elite.state["since_hit"] = regrow_delay - regrow_interval
		_show(elite)
	if elite.state["layers"] > 0 and elite.entered:
		elite.state["ring"] -= delta
		if elite.state["ring"] <= 0.0:
			elite.state["ring"] = ring_interval
			var turn := randf() * TAU
			for i in ring_shards:
				elite.fire(Vector2.DOWN.rotated(turn + TAU * i / ring_shards), ring_speed)


func absorb(elite: Elite, amount: int, hitbox: Hitbox) -> int:
	elite.state["since_hit"] = 0.0
	if elite.state["layers"] <= 0:
		return amount
	var pierce: Variant = hitbox.get("pierce")
	var heavy: bool = amount >= 2 or (pierce is int and pierce > 0)
	elite.state["ice"] -= amount * (heavy_mult if heavy else 1)
	while elite.state["ice"] <= 0 and elite.state["layers"] > 0:
		elite.state["layers"] -= 1
		elite.state["ice"] += layer_hp
		EventBus.elite_trait_broken.emit(elite.global_position)
	_show(elite)
	return 0


func _show(elite: Elite) -> void:
	(elite.state["visual"] as Node).call("set_layers", elite.state["layers"], layers)
