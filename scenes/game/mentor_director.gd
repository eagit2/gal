class_name MentorDirector
extends Node
## Runs the mentor cutscenes (CutsceneDef, rules in MentorRules): counts deaths in a row on the
## stage, plays the lend on the restart after enough of them, and the take-back once the stage is
## cleared. The game holds (tree paused) while one plays.

const CUTSCENES: Array[CutsceneDef] = [preload("res://data/cutscenes/stage18_mentor.tres")]

var player: Player
var playing := false
var _stage: StringName = &""


func _ready() -> void:
	EventBus.stage_started.connect(_on_stage_started)
	EventBus.ship_struck.connect(func() -> void: _each(func(m: Dictionary, def: CutsceneDef) -> void: MentorRules.struck(m, _stage, def)))
	EventBus.player_died.connect(func(_l: int) -> void: _each(func(m: Dictionary, def: CutsceneDef) -> void: MentorRules.died(m, _stage, def)))


## Dev option: the lend plays at the start of the stage as if the deaths had happened.
func force_intro() -> void:
	for def in CUTSCENES:
		var m := _record(def)
		m.merge(MentorRules.fresh(), true)
		m["deaths"] = def.deaths_to_trigger


func _record(def: CutsceneDef) -> Dictionary:
	return MentorRules.record(SaveManager.data, def)


func _each(step: Callable) -> void:
	for def in CUTSCENES:
		step.call(_record(def), def)


func _on_stage_started(stage_id: StringName) -> void:
	_stage = stage_id
	_each(func(m: Dictionary, def: CutsceneDef) -> void: MentorRules.stage_started(m, stage_id, def))


## Plays a due lend before `stage_id` starts, then calls `then`. False when none is due.
func intercept_start(stage_id: StringName, then: Callable) -> bool:
	for def in CUTSCENES:
		var m := _record(def)
		if MentorRules.wants_intro(m, stage_id, def):
			var lend := func() -> void:
				MentorRules.grant(Hangar.CATALOG, Hangar.state(), m, def)
				Hangar.commit()
			_play(def, MentorCutscene.Kind.LEND, def.intro_line, lend, then)
			return true
	return false


## Plays a due take-back after `stage_id` is cleared, then calls `then`. False when none is due.
func intercept_clear(stage_id: StringName, then: Callable) -> bool:
	for def in CUTSCENES:
		var m := _record(def)
		MentorRules.cleared(m, stage_id, def)
		if MentorRules.wants_take_back(m, stage_id, def):
			var give_back := func() -> void:
				MentorRules.take_back(Hangar.state(), m, def)
				Hangar.commit()
			_play(def, MentorCutscene.Kind.RETURN, MentorRules.take_back_line(m, def), give_back, then)
			return true
	return false


func _play(def: CutsceneDef, kind: MentorCutscene.Kind, line: String, hand_over: Callable, then: Callable) -> void:
	playing = true
	get_tree().paused = true
	EventBus.cutscene_started.emit(def.id)
	var scene := MentorCutscene.new()
	scene.on_hand_over = hand_over
	scene.setup(def, kind, line, player.make_ship_copy(), player.global_position)
	var done := func() -> void:
		playing = false
		get_tree().paused = false
		EventBus.cutscene_finished.emit(def.id)
		then.call()
	scene.finished.connect(done)
	get_parent().add_child(scene)
