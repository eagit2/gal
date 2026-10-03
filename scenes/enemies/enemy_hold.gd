class_name EnemyHold
extends RefCounted
## Weapon effects that take an enemy over (bubble trap, hypnosis, gravity pull) live as named child
## nodes of the Enemy and switch its own physics off while they hold it. When one lets go, the enemy
## acts again only if no other holder is still on it; an enemy pulled out of formation flies back.

const HOLDERS: Array[StringName] = [&"BubbleTrap", &"HypnoControl", &"GravityPull"]


## Whether `enemy` has a holder other than `except`.
static func held_by_other(enemy: Node, except: Node = null) -> bool:
	for holder_name in HOLDERS:
		var node := enemy.get_node_or_null(NodePath(holder_name))
		if node != null and node != except and not node.is_queued_for_deletion():
			return true
	return false


## Stops `enemy` acting on its own.
static func grab(enemy: Enemy) -> void:
	enemy.set_physics_process(false)


## `holder` lets go of `enemy`: it acts again (unless still held) and heads back to its slot.
static func release(enemy: Enemy, holder: Node) -> void:
	if not is_instance_valid(enemy) or held_by_other(enemy, holder):
		return
	enemy.set_physics_process(true)
	if enemy.state == Enemy.State.IN_FORMATION:
		enemy.state = Enemy.State.RETURNING
	elif enemy.state == Enemy.State.ENTERING and enemy.slot != Enemy.NO_SLOT:
		enemy.state = Enemy.State.TO_SLOT
