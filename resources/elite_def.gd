class_name EliteDef
extends Resource
## A tough named enemy with one trait (EliteTrait) the player has to work around. Elites enter
## after the stage's waves start, patrol the upper screen, fire fans at the player, and stay
## until destroyed. The stage isn't cleared while one lives.

@export var id: StringName
@export var display_name: String
## One line shown when it arrives: what it does and how to beat it.
@export var hint: String
@export var hp: int = 40
@export var score: int = 2000
## Scrap it leaves, split into a few piles.
@export var scrap: int = 20
## Patrol speed, pixels per second.
@export var speed: float = 70.0
## Seconds between fans of aimed shots.
@export var fire_interval: float = 1.6
@export var fan_shots: int = 3
@export var bullet_speed: float = 260.0
@export var visual_scene: PackedScene
@export var visual_scale: float = 1.8
@export var tint: Color = Color.WHITE
@export var trait_logic: EliteTrait
## More traits on top of `trait_logic` (the roster sheet fills this).
@export var traits: Array[EliteTrait] = []
## Boss phases, highest `at` first. Empty for ordinary elites.
@export var phases: Array[BossPhase] = []


## Traits active in phase `index`: the elite's own traits plus that phase's (-1: own only).
func traits_for_phase(index: int) -> Array[EliteTrait]:
	var active: Array[EliteTrait] = []
	if trait_logic:
		active.append(trait_logic)
	active.append_array(traits)
	if index >= 0 and index < phases.size():
		active.append_array(phases[index].traits)
	return active


## Phase for an hp fraction (1.0 = full): the last phase whose `at` the fraction has reached.
func phase_at(fraction: float) -> int:
	var index := 0
	for i in phases.size():
		if fraction <= phases[i].at:
			index = i
	return index
