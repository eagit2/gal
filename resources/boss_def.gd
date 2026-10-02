class_name BossDef
extends Resource

@export var id: StringName
@export var hp: int = 200
## Each phase: {"hp_threshold": float 0..1, "attacks": Array[StringName], "movement": StringName}
@export var phases: Array[Dictionary] = []
