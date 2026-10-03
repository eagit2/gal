class_name Hitbox
extends Area2D
## The area that deals damage to Hurtboxes it overlaps.

signal hit(hurtbox: Hurtbox)

@export var damage: int = 1
## Stop dealing damage after the first hit (bullets).
@export var single_hit := false
var spent := false


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if spent or not area is Hurtbox:
		return
	var hurtbox := area as Hurtbox
	if hurtbox.invulnerable:
		return
	# Spent before emitting so a hit handler can re-arm the hitbox (piercing shots).
	if single_hit:
		spent = true
	hurtbox.take_hit(self)
	hit.emit(hurtbox)
