class_name HiveTowTrait
extends EliteTrait
## Tows a hive pod that hatches a swarm of diving enemies every `spawn_interval`. Counter: destroy
## the pod first (it has its own hp); kill the carrier instead and the pod falls like a rock,
## crushing enemies below it.

@export var pod_scene: PackedScene
@export var pod_hp := 30
@export var swarm_enemy: EnemyDef
@export var swarm := 3
@export var spawn_interval := 6.0
@export var tether_length := 120.0


func begin(elite: Elite) -> void:
	var pod: Node2D = pod_scene.instantiate()
	pod.call("setup", elite, maxi(1, roundi(pod_hp * elite.difficulty.enemy_hp)), tether_length, swarm_enemy, swarm, spawn_interval)
	elite.entities.add_child.call_deferred(pod)
	elite.state["pod"] = pod


func end(elite: Elite) -> void:
	var pod: Variant = elite.state.get("pod")
	if is_instance_valid(pod):
		pod.call("drop")
