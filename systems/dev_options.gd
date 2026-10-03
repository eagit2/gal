class_name DevOptions
extends RefCounted
## Playtest shortcuts, so a level can be tested without playing up to it.
## Web: URL query, e.g. https://eagit2.github.io/gal/?stage=3&god=1&repeat=1&difficulty=ace
## Desktop: user args after `--`, e.g. godot -- stage=3 god=1
##   stage       1-based stage number, or a stage id (challenge_1)
##   god         player hits cost no lives
##   repeat      replay the same stage instead of advancing
##   difficulty  cadet | pilot | ace | nightmare
##   capture     capture runs start at 3s and repeat every few seconds
##   elite       an elite id (frost_shell, rock_hauler, shield_warden) that joins every stage at 4s

var stage := ""
var god := false
var repeat := false
var difficulty: StringName = &""
var elite: StringName = &""
var capture := false


static func from_environment() -> DevOptions:
	var args := OS.get_cmdline_user_args()
	if OS.has_feature("web"):
		var query: Variant = JavaScriptBridge.eval("window.location.search", true)
		if query is String:
			args = (query as String).trim_prefix("?").split("&", false)
	return parse(args)


static func parse(args: PackedStringArray) -> DevOptions:
	var opts := DevOptions.new()
	for arg in args:
		var pair := arg.trim_prefix("--").split("=", true, 1)
		var key := pair[0].to_lower()
		var value := pair[1].uri_decode() if pair.size() > 1 else "1"
		match key:
			"stage":
				opts.stage = value
			"god":
				opts.god = value != "0"
			"repeat":
				opts.repeat = value != "0"
			"difficulty":
				opts.difficulty = StringName(value.to_lower())
			"capture":
				opts.capture = value != "0"
			"elite":
				opts.elite = StringName(value.to_lower())
	return opts


## True when any option is set. Dev runs leave the saved run alone.
func is_set() -> bool:
	return not stage.is_empty() or god or repeat or difficulty != &"" or elite != &"" or capture


## Index into `stages` for the `stage` option, or `fallback` when unset or unknown.
func stage_index(stages: Array[StageDef], fallback: int) -> int:
	if stage.is_empty():
		return fallback
	if stage.is_valid_int():
		return maxi(stage.to_int() - 1, 0)
	for i in stages.size():
		if String(stages[i].id) == stage:
			return i
	return fallback
