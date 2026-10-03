extends Node2D
## Shield feedback: a flash when the bubble absorbs a hit, a shatter where it pops, and a
## quick grow-in when it recharges. Listens to the shield node above this visual
## (signals `hurt`, `popped`, `restored`), so it needs no code in the shield itself.

const POP_SCENE := preload("res://assets/art/dusk_armada/fx/shield_pop.tscn")
const FLASH_TIME := 0.15

@export var sprite: Sprite2D
var _flash := 0.0


func _ready() -> void:
	set_process(false)
	var shield := _find_shield()
	if shield == null:
		return
	shield.connect(&"hurt", func(_hitbox: Node) -> void: _start_flash())
	shield.connect(&"popped", _on_popped.bind(shield))
	shield.connect(&"restored", _on_restored)


func _find_shield() -> Node2D:
	var node := get_parent()
	while node:
		if node.has_signal(&"popped") and node.has_signal(&"restored"):
			return node as Node2D
		node = node.get_parent()
	return null


func _start_flash() -> void:
	_flash = FLASH_TIME
	set_process(true)


func _on_popped(shield: Node2D) -> void:
	var fx: Node2D = POP_SCENE.instantiate()
	var host := shield.get_parent().get_parent() if shield.get_parent() else shield
	host.add_child(fx)
	fx.global_position = shield.global_position


func _on_restored() -> void:
	var holder := get_parent() as Node2D
	holder.scale = Vector2(0.4, 0.4)
	create_tween().tween_property(holder, ^"scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)
	(sprite.material as ShaderMaterial).set_shader_parameter(&"flash", _flash / FLASH_TIME)
	if _flash <= 0.0:
		set_process(false)
