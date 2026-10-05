extends Node
## Music and pooled SFX. Buses: Master > Music, SFX, UI (created at runtime until a bus layout is authored).
## Sounds are data (data/audio/sound_bank.tres); AudioCues maps EventBus signals to them.
## Browsers start audio on the first input; Godot resumes the web audio context by itself.

const SFX_POOL_SIZE := 16
const BANK: SoundBank = preload("res://data/audio/sound_bank.tres")
const FADE_TIME := 0.6
const SILENT_DB := -60.0

var cues: AudioCues
var _music: Array[AudioStreamPlayer] = []
var _active := 0
var _music_tweens: Array[Tween] = [null, null]
var _sfx_pool: Array[AudioStreamPlayer] = []
var _voice_priority: Array[int] = []
var _sfx: Dictionary = {}
var _last_played: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus_name in ["Music", "SFX", "UI"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = "Music"
		add_child(player)
		_music.append(player)
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		player.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(player)
		_sfx_pool.append(player)
		_voice_priority.append(0)
	for def in BANK.sfx:
		_sfx[def.id] = def
	set_muted(SaveManager.data["settings"].get("muted", false))
	cues = AudioCues.new()
	add_child(cues)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mute"):
		set_muted(not AudioServer.is_bus_mute(0))
		SaveManager.data["settings"]["muted"] = AudioServer.is_bus_mute(0)
		SaveManager.save()


func current_music() -> AudioStream:
	var player := _music[_active]
	return player.stream if player.playing else null


## Crossfades to stream. Null fades the music out. Asking for a track that is still fading out
## (restart right after game over, a style that flips back) fades that player back in instead
## of leaving silence or restarting the track.
func play_music(stream: AudioStream, fade: float = FADE_TIME) -> void:
	if stream != null and _music[_active].stream == stream and _music[_active].playing:
		_fade(_active, 0.0, fade, false)
		return
	var old := _music[_active]
	if old.playing:
		_fade(_active, SILENT_DB, fade, true)
	if stream == null:
		return
	_active = 1 - _active
	var new := _music[_active]
	if new.stream == stream and new.playing:
		_fade(_active, 0.0, fade, false)
		return
	new.stop()
	new.stream = stream
	new.volume_db = SILENT_DB if fade > 0.0 else 0.0
	# Always from the loop start: seeking a looping track can glitch under web sample playback.
	new.play()
	_fade(_active, 0.0, fade, false)


func _fade(index: int, to_db: float, time: float, stop_after: bool) -> void:
	if _music_tweens[index]:
		_music_tweens[index].kill()
	var player := _music[index]
	# Combos change Engine.time_scale; fades keep real time.
	var tween := create_tween().set_ignore_time_scale(true)
	tween.tween_property(player, "volume_db", to_db, maxf(time, 0.01))
	if stop_after:
		tween.tween_callback(player.stop)
	_music_tweens[index] = tween


func stop_music(fade: float = FADE_TIME) -> void:
	play_music(null, fade)


## Plays a sound from the bank by id. Returns false when it was skipped (cooldown or no voice).
func play(id: StringName, pitch: float = 1.0) -> bool:
	var def: SfxDef = _sfx.get(id)
	if def == null or def.streams.is_empty():
		push_warning("AudioManager: no sound '%s'" % id)
		return false
	var now := Time.get_ticks_msec() / 1000.0
	if def.cooldown > 0.0 and now - _last_played.get(id, -INF) < def.cooldown:
		return false
	var voice := _pick_voice(def.priority)
	if voice == -1:
		return false
	_last_played[id] = now
	var player := _sfx_pool[voice]
	player.stream = def.streams.pick_random()
	player.bus = def.bus
	player.volume_db = def.volume_db
	player.pitch_scale = pitch * (1.0 + randf_range(-def.pitch_variance, def.pitch_variance))
	player.play()
	_voice_priority[voice] = def.priority
	return true


## Plays a raw stream on the SFX bus (prefer play(id) so the sound is tunable as data).
func play_sfx(stream: AudioStream, pitch_variance: float = 0.05) -> void:
	var voice := _pick_voice(5)
	if voice == -1:
		return
	var player := _sfx_pool[voice]
	player.stream = stream
	player.bus = "SFX"
	player.volume_db = 0.0
	player.pitch_scale = 1.0 + randf_range(-pitch_variance, pitch_variance)
	player.play()
	_voice_priority[voice] = 5


## A free voice, else the lowest-priority busy voice below `priority`, else -1.
func _pick_voice(priority: int) -> int:
	var lowest := -1
	for i in SFX_POOL_SIZE:
		if not _sfx_pool[i].playing:
			return i
		if _voice_priority[i] < priority and (lowest == -1 or _voice_priority[i] < _voice_priority[lowest]):
			lowest = i
	return lowest


func has_sound(id: StringName) -> bool:
	return _sfx.has(id)


func set_bus_volume(bus_name: String, linear: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), linear_to_db(linear))


func set_muted(muted: bool) -> void:
	AudioServer.set_bus_mute(0, muted)

