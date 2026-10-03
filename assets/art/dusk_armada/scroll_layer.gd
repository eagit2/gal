extends Node2D
## Scrolls a vertically tiling layer downward forever. Children are placed by the scene:
## one copy at y=0 and one at y=-tile_height.

@export var speed := 12.0
@export var tile_height := 960.0


func _process(delta: float) -> void:
	position.y = fmod(position.y + speed * delta, tile_height)
