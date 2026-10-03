class_name AudioCues
extends Node
## Turns game events into sounds and music. Lives under AudioManager, so it works in every scene
## without gameplay code knowing about audio. Music follows the art style (ThemeDef.music):
## stages play their style's track, combo modes crossfade to theirs, boss stages use the boss track.

const STAGES_DIR := "res://data/stages/%s.tres"
## Every sound id this script plays directly (tests check they exist in the bank).
const CUES: Array[StringName] = [&"shot", &"player_hit", &"shield_pop", &"shield_restore",
		&"stage_start", &"stage_clear", &"game_over", &"upgrade_pick", &"ui_move", &"ui_confirm"]
## M3 signals (combos, grazes, synergies). Connected only if EventBus has them.
const OPTIONAL_CUES := {
	&"shot_hit": &"shot_hit",
	&"bullet_grazed": &"graze",
	&"combo_started": &"combo_start",
	&"combo_ended": &"combo_end",
	&"synergy_activated": &"synergy",
	&"power_used": &"combo_start",
	&"medal_earned": &"pickup",
	&"module_mastered": &"synergy",
}

var _shield_up := true
var _boss_stage := false
var _in_run := false


func _ready() -> void:
	EventBus.shot_fired.connect(_cue.bind(&"shot"))
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.player_hit.connect(_cue.bind(&"player_hit"))
	EventBus.shield_changed.connect(_on_shield_changed)
	EventBus.stage_started.connect(_on_stage_started)
	EventBus.stage_cleared.connect(_cue.bind(&"stage_clear").unbind(1))
	EventBus.run_started.connect(_on_run_started.unbind(1))
	EventBus.run_ended.connect(_on_run_ended)
	EventBus.upgrade_picked.connect(_cue.bind(&"upgrade_pick").unbind(1))
	for signal_name: StringName in OPTIONAL_CUES:
		if EventBus.has_signal(signal_name):
			var cue: Callable = _cue.bind(OPTIONAL_CUES[signal_name])
			var args := _signal_arg_count(signal_name)
			EventBus.connect(signal_name, cue.unbind(args) if args > 0 else cue)
	get_tree().node_added.connect(_on_node_added)
	get_tree().scene_changed.connect(_on_scene_changed)
	get_viewport().gui_focus_changed.connect(_cue.bind(&"ui_move").unbind(1))
	# StyleDirector is a later autoload; it is ready once the tree is.
	_connect_style.call_deferred()


func _connect_style() -> void:
	StyleDirector.style_changed.connect(_on_style_changed)


func _cue(id: StringName) -> void:
	AudioManager.play(id)


func _signal_arg_count(signal_name: StringName) -> int:
	for info in EventBus.get_signal_list():
		if info["name"] == signal_name:
			return info["args"].size()
	return 0


## Music for the game scene: the boss track on boss stages, else the active style's track.
func stage_music() -> AudioStream:
	if _boss_stage and AudioManager.BANK.boss_music:
		return AudioManager.BANK.boss_music
	var theme: ThemeDef = StyleDirector.current
	if theme.music:
		return theme.music
	return StyleDirector.THEMES[StyleDirector.BASE_THEME].music


func _on_enemy_killed(enemy: Node2D, _position: Vector2, _score: int) -> void:
	var def: EnemyDef = enemy.get("def") as EnemyDef
	AudioManager.play(def.death_sound if def else &"explode_small")


## The shield reports its charge in steps: 0 means it just popped, 1 means it is back.
func _on_shield_changed(charge: float) -> void:
	if charge <= 0.0 and _shield_up:
		_shield_up = false
		AudioManager.play(&"shield_pop")
	elif charge >= 1.0 and not _shield_up:
		_shield_up = true
		AudioManager.play(&"shield_restore")


func _on_run_started() -> void:
	_in_run = true
	_shield_up = true


func _on_stage_started(stage_id: StringName) -> void:
	_in_run = true
	var path := STAGES_DIR % stage_id
	var stage: StageDef = load(path) if ResourceLoader.exists(path) else null
	_boss_stage = stage != null and stage.boss
	AudioManager.play(&"stage_start")
	AudioManager.play_music(stage_music())


func _on_run_ended(_victory: bool) -> void:
	_in_run = false
	AudioManager.stop_music(1.2)
	AudioManager.play(&"game_over")


func _on_style_changed(_theme: ThemeDef) -> void:
	if _in_run:
		AudioManager.play_music(stage_music())


func _on_scene_changed() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var music: AudioStream = AudioManager.BANK.scene_music.get(scene.scene_file_path)
	if music:
		_in_run = false
		AudioManager.play_music(music)


## Every button in every menu clicks when pressed.
func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		(node as BaseButton).pressed.connect(_cue.bind(&"ui_confirm"))
