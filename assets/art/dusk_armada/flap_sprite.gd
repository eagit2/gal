class_name FlapSprite
extends Sprite2D
## Plays a horizontal frame strip (hframes) at a fixed rate.
## Looping strips start at a random phase so a formation doesn't flap in sync.

@export var fps := 4.0
@export var loop := true
var _t := 0.0


func _ready() -> void:
	if loop:
		_t = randf() * hframes / fps


func _process(delta: float) -> void:
	_t += delta
	var f := int(_t * fps)
	frame = f % hframes if loop else mini(f, hframes - 1)
