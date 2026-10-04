class_name OrbitDrone
extends Node2D
## One of the Orbit Warden's drones: a small armored orb that soaks player shots on its own
## hurtbox and can be shot down. Touching it costs a life.

const FADE_IN := 0.5

var _age := 0.0

@onready var health: Health = $Health


func setup(hp: int) -> void:
	$Health.max_hp = hp


func _ready() -> void:
	health.reset(health.max_hp)
	health.died.connect(queue_free)
	health.damaged.connect(func(_a: int) -> void: ($Visual as Node2D).call(&"set_fraction", float(health.hp) / health.max_hp))
	$ContactHitbox.hit.connect(func(_h: Hurtbox) -> void: health.take_damage(1))


func _process(delta: float) -> void:
	_age += delta
	modulate.a = clampf(_age / FADE_IN, 0.0, 1.0)
