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
## A player shot hit an enemy (Lock-On meter).
signal shot_hit()
signal shot_missed()
## An enemy shot passed close to the player without hitting (Graze meter).
signal bullet_grazed(position: Vector2)
## A captured ship was rescued (Arcade '81; capture arrives in M5).
signal ship_rescued()
signal player_died(lives_left: int)
signal lives_changed(lives: int)
signal score_changed(score: int)
signal upgrade_picked(upgrade_id: StringName)
## Run stats were recomputed (upgrade gained, synergy, combo started or ended).
signal stats_changed()
signal synergy_activated(synergy: SynergyDef)
signal combo_started(combo: ComboDef, chain: int)
signal combo_ended(combo: ComboDef)
## Meter fill in 0..1 for each combo id, sent when it changes.
signal combo_meter_changed(combo_id: StringName, fill: float)
## The player asked for their special (Cryo Pulse): key, gamepad, or two-finger tap.
signal special_requested()
signal freeze_started(duration: float)
signal freeze_ended()
## Cryo Pulse uses left this stage.
signal freeze_charges_changed(charges: int)
