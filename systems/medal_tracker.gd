class_name MedalTracker
extends RefCounted
## Follows one stage's medal goal from EventBus counts. The Hangar autoload feeds it and pays out.

var medal: MedalDef
var shots := 0
var hits := 0
var grazes := 0
var ships_lost := 0
var escapes := 0


func _init(stage_medal: MedalDef = null) -> void:
	medal = stage_medal


func earned() -> bool:
	if medal == null:
		return false
	match medal.goal:
		MedalDef.Goal.NO_DAMAGE:
			return ships_lost == 0
		MedalDef.Goal.PERFECT:
			return escapes == 0
		MedalDef.Goal.ACCURACY:
			return shots > 0 and float(hits) / shots >= medal.target
		MedalDef.Goal.GRAZES:
			return grazes >= medal.target
	return false
