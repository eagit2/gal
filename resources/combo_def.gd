class_name ComboDef
extends Resource
## One combo mode (docs/combo-styles.md): a meter filled by a style of play that triggers a timed
## buff. `style` (a ThemeDef id) would switch the art style; empty keeps the screen as is (Eric, 2026-10-03).

@export var id: StringName
@export var display_name: String
## ThemeDef id shown while the mode runs.
@export var style: StringName
## Points needed to trigger (scaled by DifficultyDef.combo_threshold). 0 = never fills from play
## (triggered directly, e.g. Arcade '81 on a ship rescue).
@export var threshold: float = 10.0
## Seconds without gaining points before the meter starts draining.
@export var decay_delay: float = 2.0
## Fraction of the threshold drained per second once idle.
@export var decay_rate: float = 0.1
@export var duration: float = 8.0
## Same format as UpgradeDef.effects, applied while the mode runs.
@export var effects: Array[Dictionary] = []
@export var color: Color = Color.WHITE
