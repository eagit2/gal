class_name SfxDef
extends Resource
## One sound effect. AudioCues plays these by id through AudioManager.play().

@export var id: StringName
## One is picked at random each time, for variety.
@export var streams: Array[AudioStream] = []
@export var volume_db: float = 0.0
@export var pitch_variance: float = 0.05
## Minimum seconds between two plays of this sound (stops machine-gun stacking).
@export var cooldown: float = 0.0
## When every voice is busy, a sound may only steal a voice playing a lower priority.
@export_range(0, 10) var priority: int = 5
@export var bus: StringName = &"SFX"
