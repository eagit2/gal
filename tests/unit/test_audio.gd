extends TestCase
## The sound bank is complete and music loops.

const BANK_PATH := "res://data/audio/sound_bank.tres"


func _bank_ids() -> Array[StringName]:
	var bank: SoundBank = load(BANK_PATH)
	var ids: Array[StringName] = []
	for def in bank.sfx:
		ids.append(def.id)
	return ids


func test_every_sound_has_a_stream() -> void:
	var bank: SoundBank = load(BANK_PATH)
	for def in bank.sfx:
		expect_true(not def.streams.is_empty() and def.streams.all(func(s: AudioStream) -> bool: return s != null),
				"%s has streams" % def.id)


func test_sound_ids_are_unique() -> void:
	var ids := _bank_ids()
	for id in ids:
		expect_eq(ids.count(id), 1, "%s once" % id)


func test_cues_exist_in_bank() -> void:
	var ids := _bank_ids()
	var wanted: Array[StringName] = AudioCues.CUES.duplicate()
	wanted.append_array(AudioCues.OPTIONAL_CUES.values())
	for file in DirAccess.get_files_at("res://data/enemies"):
		if file.ends_with(".tres"):
			wanted.append((load("res://data/enemies/" + file) as EnemyDef).death_sound)
	for id in wanted:
		expect_true(id in ids, "%s in bank" % id)


func test_music_loops() -> void:
	var bank: SoundBank = load(BANK_PATH)
	var tracks: Array[AudioStream] = [bank.boss_music]
	tracks.append_array(bank.scene_music.values())
	for file in DirAccess.get_files_at("res://data/themes"):
		if file.ends_with(".tres"):
			tracks.append((load("res://data/themes/" + file) as ThemeDef).music)
	for track in tracks:
		expect_true(track is AudioStreamOggVorbis and (track as AudioStreamOggVorbis).loop,
				"%s loops" % (track.resource_path if track else "missing track"))
