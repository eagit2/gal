class_name MedalDef
extends Resource
## Optional per-stage goal. Paid in credits (scaled by DifficultyDef.score_multiplier) the first
## time it is earned each run.

enum Goal {
	NO_DAMAGE,  ## lose no ship during the stage
	PERFECT,  ## no enemy escapes (challenge stages)
	ACCURACY,  ## hits / shots >= target (0..1)
	GRAZES,  ## at least `target` grazes
}

@export var id: StringName
@export var display_name: String
@export var description: String
@export var goal: Goal
@export var target: float = 0.0
@export var currency: int = 20
