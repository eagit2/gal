class_name Health
extends Node
## Hit points. Emits died once when hp reaches zero.

signal damaged(amount: int)
signal died

@export var max_hp: int = 1
var hp: int = 1


func _ready() -> void:
	hp = max_hp


func reset(value: int) -> void:
	max_hp = value
	hp = value


func take_damage(amount: int) -> void:
	if hp <= 0:
		return
	hp = maxi(hp - amount, 0)
	damaged.emit(amount)
	if hp == 0:
		died.emit()
