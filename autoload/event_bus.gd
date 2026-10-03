extends Node
## Global signals only. No state lives here.

signal run_started(difficulty_id: StringName)
signal run_ended(victory: bool)
signal stage_started(stage_id: StringName)
signal stage_cleared(stage_id: StringName)
signal enemy_killed(enemy: Node2D, position: Vector2, score: int)
## An enemy left the screen without being killed (challenge stages).
signal enemy_escaped(enemy: Node2D)
signal player_hit()
## Shield charge in 0..1 (1 = bubble up), reported in 10% steps.
signal shield_changed(charge: float)
signal shot_fired()
signal shot_missed()
signal player_died(lives_left: int)
signal score_changed(score: int)
signal upgrade_picked(upgrade_id: StringName)
