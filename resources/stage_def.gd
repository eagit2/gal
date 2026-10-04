class_name StageDef
extends Resource

@export var id: StringName
@export var waves: Array[WaveDef] = []
## Challenging stage: enemies fly through without settling or shooting; hits earn a bonus.
@export var is_challenge: bool = false
## ThemeDef id forced for the whole stage; empty keeps the base style.
@export var style: StringName = &""
## Extra squads that fly into empty formation slots once the main waves are in and the
## formation thins out below `reinforce_below` enemies.
@export var reinforcements: int = 0
@export var reinforcement_size: int = 8
@export var reinforce_below: int = 18
@export var modifiers: Array[StringName] = []
@export_range(0, 3) var music_intensity: int = 1
## Optional goal that pays hangar credits once per run (see MedalTracker).
@export var medal: MedalDef
## Elites that join this stage, `elite_delay` seconds in and `elite_gap` apart. The stage isn't
## cleared while one lives.
@export var elites: Array[EliteDef] = []
@export var elite_delay: float = 9.0
@export var elite_gap: float = 12.0
## Elites drawn at random each run from `elite_pool`, after the fixed `elites`.
@export var elite_pool: Array[EliteDef] = []
@export var elite_picks: int = 0
## Roster sheet ids (elites.csv, bosses.csv) added to `elites` and `elite_pool`, for elites and
## bosses that only exist in the sheet.
@export var elite_ids: Array[StringName] = []
@export var elite_pool_ids: Array[StringName] = []
## Multiplies every enemy's and elite's hp on this stage (later stages hit harder).
@export var enemy_hp_mult: float = 1.0
## Chance that a scrap pile is a Mimic in disguise.
@export var mimic_chance: float = 0.0


## The fixed elites plus `elite_picks` random ones from the pool.
func pick_elites() -> Array[EliteDef]:
	var picked := elites.duplicate()
	var pool := elite_pool.duplicate()
	for id in elite_ids:
		picked.append(Roster.elite(id))
	for id in elite_pool_ids:
		pool.append(Roster.elite(id))
	pool.shuffle()
	picked.append_array(pool.slice(0, elite_picks))
	return picked
## Boss stage: plays SoundBank.boss_music instead of the style's music.
@export var boss: bool = false
