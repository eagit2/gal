extends Node
## Global signals only. No state lives here.

signal run_started(difficulty_id: StringName)
signal run_ended(victory: bool)
signal stage_started(stage_id: StringName)
signal stage_cleared(stage_id: StringName)
signal enemy_killed(enemy: Node2D, position: Vector2, score: int)
signal player_hit()
signal shot_fired()
signal shot_missed()
signal player_died(lives_left: int)
signal score_changed(score: int)
signal upgrade_picked(upgrade_id: StringName)
