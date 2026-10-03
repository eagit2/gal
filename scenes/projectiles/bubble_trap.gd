class_name BubbleTrap
extends Node2D
## An enemy caught in a Bubble Blower bubble: added as the enemy's child, it stops the enemy acting,
## floats it upward for TRAP_TIME, then pops for pop_damage. A surviving enemy flies back to its
## formation slot (EnemyHold). The look is the bubble visual, scaled up around the enemy.

const NODE_NAME := &"BubbleTrap"
const VISUAL := preload("res://assets/art/dusk_armada/projectiles/bubble.tscn")
const TRAP_TIME := 1.5
const RISE := 45.0
const TOP := 40.0
const VISUAL_SCALE := 2.2

var pop_damage := 4
var size := 1.0
var _left := TRAP_TIME
var _enemy: Enemy


func _ready() -> void:
	name = NODE_NAME
	_enemy = get_parent() as Enemy
	EnemyHold.grab(_enemy)
	var look: Node2D = VISUAL.instantiate()
	look.scale = Vector2.ONE * VISUAL_SCALE * size
	add_child(look)
	# The bubble stays upright while the enemy inside may be turned.
	look.global_rotation = 0.0


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_enemy):
		return
	_enemy.position.y = maxf(TOP, _enemy.position.y - RISE * delta)
	_left -= delta
	if _left <= 0.0:
		_pop()


func _pop() -> void:
	set_physics_process(false)
	EnemyHold.release(_enemy, self)
	var enemy := _enemy
	queue_free()
	enemy.damage(pop_damage)
