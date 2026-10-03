class_name EliteTrait
extends Resource
## Behavior that makes an elite unique; an elite or boss phase can carry several. Shared between
## elites, so per-elite state lives in `state(elite)`, one Dictionary per trait per elite.
## Override the hooks you need.


func state(elite: Elite) -> Dictionary:
	return elite.state.get_or_add(self, {})


func begin(_elite: Elite) -> void:
	pass


func tick(_elite: Elite, _delta: float) -> void:
	pass


## Damage a hit on the elite's own hurtbox actually deals after the trait (armor, shells).
func absorb(_elite: Elite, amount: int, _hitbox: Hitbox) -> int:
	return amount


func end(_elite: Elite) -> void:
	pass


## After `end` when a boss changes phase: frees the visuals this trait hung on the elite and
## forgets its state, so a later phase can begin it fresh.
func clear(elite: Elite) -> void:
	for value: Variant in state(elite).values():
		if value is Node and is_instance_valid(value) and (value as Node).get_parent() == elite:
			(value as Node).queue_free()
	elite.state.erase(self)
