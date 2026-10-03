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
## Shield charge 0..1, or -1 when no shield part is fitted.
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
## Run stats were recomputed (hangar loadout, pilot power, combo started or ended).
signal stats_changed()
signal combo_started(combo: ComboDef, chain: int)
signal combo_ended(combo: ComboDef)
## Meter fill in 0..1 for each combo id, sent when it changes.
signal combo_meter_changed(combo_id: StringName, fill: float)
## Upgrade bubbles (BubbleSystem): a combo or triggered extra drops a bubble the ship must catch.
signal upgrade_bubble_requested(kind: StringName, is_combo: bool, label: String, tint: Color)
signal upgrade_bubble_caught(kind: StringName)
signal upgrade_bubble_lost(kind: StringName)
## Anything touched the ship: a shield layer or the hull (no-hit stage tracking).
signal ship_struck()
## The companion drone rammed an enemy.
signal companion_lost(at: Vector2)
## A stage medal was earned and paid `credits` hangar credits.
signal medal_earned(medal: MedalDef, credits: int)
signal credits_changed(credits: int)
## The hangar loadout, frames or modules changed.
signal hangar_changed()
## An equipped module reached max level (it also spawned a fresh copy the first time).
## The pilot power recharged to `charge` (0..1), reported in 10% steps.
signal power_changed(charge: float)
signal power_used(pilot: PilotDef)
## Cryo Pulse fired (on its own) and froze the field for `duration` seconds.
signal freeze_started(duration: float)
signal freeze_ended()
## Cryo Pulse uses left this stage.
signal freeze_charges_changed(charges: int)
## The ship picked up `amount` scrap (already multiplied) at `at`.
signal scrap_collected(amount: int, at: Vector2)
## A loose scrap pile appears at `at` (elite kills, rock chunks).
signal scrap_dropped(at: Vector2, amount: int)
signal elite_spawned(elite: EliteDef)
signal elite_killed(elite: EliteDef, at: Vector2)
## An elite's trait was beaten for now (an ice layer shattered, a tether cut).
signal elite_trait_broken(at: Vector2)
## A tractor beam caught the player's ship (costs a life; the ship rides above `captor`).
signal player_captured(captor: Node2D)
## The captor died in formation, so the captured ship is gone.
signal captive_lost()
## The dual fighter's wingman took a hit and is gone.
signal wingman_lost(at: Vector2)
## SaveManager switched to (or started fresh in) a save slot; `data` now holds that slot.
signal save_slot_loaded(slot: int)
