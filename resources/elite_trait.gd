class_name EliteTrait
extends Resource
## Behavior that makes an elite unique. Shared between elites, so per-elite state lives in
## `elite.state` (a Dictionary). Override the hooks you need.


func begin(_elite: Elite) -> void:
	pass


func tick(_elite: Elite, _delta: float) -> void:
	pass


## Damage a hit on the elite's own hurtbox actually deals after the trait (armor, shells).
func absorb(_elite: Elite, amount: int, _hitbox: Hitbox) -> int:
	return amount


func end(_elite: Elite) -> void:
	pass
