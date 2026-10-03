class_name Crusher
extends Area2D
## Falling mass (rocks, chunks, dropped pods): damages any enemy or elite it passes through,
## except `ignore` (the thing that dropped it). Scans enemy hurtboxes (layer 2).

@export var enemy_damage := 99
@export var elite_damage := 12
var ignore: Node


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	var body := area.get_parent()
	if body == ignore or not area is Hurtbox:
		return
	if body is Enemy:
		(body as Enemy).damage(enemy_damage)
	elif body is Elite:
		(body as Elite).damage(elite_damage)
