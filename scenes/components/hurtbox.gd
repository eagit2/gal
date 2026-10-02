class_name Hurtbox
extends Area2D
## The area that can be hit. Passes damage to an optional Health.

signal hurt(hitbox: Hitbox)

@export var health: Health
var invulnerable := false


func take_hit(hitbox: Hitbox) -> void:
	if invulnerable:
		return
	if health:
		health.take_damage(hitbox.damage)
	hurt.emit(hitbox)
