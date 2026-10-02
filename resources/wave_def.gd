class_name WaveDef
extends Resource
## A group of one enemy type entering along one path, one after another.

@export var enemy: EnemyDef
@export var count: int = 4
## Absolute screen-space path. Enemies fly to their slot after its end, or leave if they have none.
@export var entry_path: Curve2D
## One slot (column, row) per enemy. Missing entries mean the enemy flies through and leaves.
@export var formation_slots: Array[Vector2i] = []
## Seconds after stage start.
@export var delay: float = 0.0
