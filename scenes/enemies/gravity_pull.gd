class_name GravityPull
extends Node
## An enemy caught by one or more Gravity Gun wells: added as the enemy's child, it holds the enemy
## (EnemyHold) while the wells drag it. When the last well drops it, the enemy acts again and flies
## back to its slot.

const NODE_NAME := &"GravityPull"

## Wells still pulling this enemy.
var wells: Array[Node] = []


func _ready() -> void:
	name = NODE_NAME
	EnemyHold.grab(get_parent() as Enemy)


## `well` stops pulling; the last one lets the enemy go.
func drop(well: Node) -> void:
	wells.erase(well)
	if not wells.is_empty() or is_queued_for_deletion():
		return
	var enemy := get_parent() as Enemy
	queue_free()
	EnemyHold.release(enemy, self)
