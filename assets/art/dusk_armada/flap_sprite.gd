class_name FlapSprite
extends Sprite2D
## Plays a horizontal frame strip (hframes) at a fixed rate.
## Looping strips start at a random phase so a formation doesn't flap in sync.
## Strips with damaged frames hold `anim_frames` normal frames, then the same count damaged.

@export var fps := 4.0
@export var loop := true
## Frames per animation; 0 means all hframes.
@export var anim_frames := 0
var _t := 0.0
var _offset := 0


func _ready() -> void:
	if anim_frames <= 0:
		anim_frames = hframes
	if loop:
		_t = randf() * anim_frames / fps


func _process(delta: float) -> void:
	_t += delta
	var f := int(_t * fps)
	frame = _offset + (f % anim_frames if loop else mini(f, anim_frames - 1))


## Switches to the damaged frames if the strip has them.
func show_damaged() -> void:
	if hframes >= anim_frames * 2:
		_offset = anim_frames
