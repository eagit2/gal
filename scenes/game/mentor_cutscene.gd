class_name MentorCutscene
extends CanvasLayer
## A mentor moment over the paused game (CutsceneDef): a tinted copy of the player's ship flies in,
## talks, and hands the weapon over (LEND, with a demo on a few enemies) or takes it back (RETURN).
## Tap, click or any key skips; the hand-over still happens.

signal finished

const OVERLAY := preload("res://assets/art/dusk_armada/cutscene/mentor_overlay.tscn")
enum Kind { LEND, RETURN }
const ENTER := 1.2
const LEAVE := 1.0
const SKIP_GUARD := 0.4
const START := Vector2(-60, 560)
const EXIT := Vector2(620, 420)

var kind: Kind
var def: CutsceneDef
## Called once when the weapon changes hands.
var on_hand_over: Callable
var _ship: Node2D
var _home := Vector2(360, 780)
var _overlay: Node2D
var _t := 0.0
var _card_at := 0.0
var _leave_at := 0.0
var _handed := false
var _done := false


## `ship` is a copy of the player's look; `ship_at` is where the player sits.
func setup(cutscene: CutsceneDef, play_kind: Kind, line: String, ship: Node2D, ship_at: Vector2) -> void:
	def = cutscene
	kind = play_kind
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay = OVERLAY.instantiate()
	add_child(_overlay)
	_ship = ship
	_ship.modulate = def.mentor_tint
	_ship.position = START
	add_child(_ship)
	_home = ship_at + Vector2(90, -70)
	var talk := maxf(2.4, line.length() / 32.0 + 1.6)
	_card_at = ENTER + talk
	_leave_at = _card_at + (4.4 if kind == Kind.LEND else 2.4)
	_overlay.set(&"speaker", def.speaker)
	_overlay.set(&"line", line)
	_overlay.set(&"line_start", ENTER)
	_overlay.set(&"card_start", _card_at)
	_overlay.set(&"shooter", ship_at)
	_fill_card()
	if kind == Kind.LEND:
		var enemy := Roster.enemy(def.demo_enemy)
		_overlay.set(&"demo_scene", enemy.visual_scene if enemy else null)
		_overlay.set(&"demo_count", def.demo_count)
		_overlay.set(&"demo_start", _card_at + 0.6)


func _fill_card() -> void:
	var part := Hangar.CATALOG.part(def.grant_part)
	var rows: Array[String] = []
	var chips: Array[Dictionary] = []
	var combo := ""
	if kind == Kind.LEND:
		for a in part.attributes:
			rows.append("%s  MAX (%d)" % [a["name"], a["max"]])
		for id in part.locked_chips:
			var chip := Hangar.CATALOG.chip(id)
			chips.append({"name": chip.display_name.to_upper(), "color": chip.color})
		if part.locked_chips.size() >= 2:
			var link := Hangar.CATALOG.combo_for(part.locked_chips[0], part.locked_chips[1])
			combo = link.display_name.to_upper() if link else ""
		_overlay.set(&"card_title", part.display_name.to_upper())
	else:
		var chip := Hangar.CATALOG.chip(def.reward_chip)
		rows.append("RETURNED TO ITS OWNER")
		rows.append("YOUR OLD GUN IS BACK ON")
		chips.append({"name": "+1 " + chip.display_name.to_upper(), "color": chip.color})
		_overlay.set(&"card_title", part.display_name.to_upper())
	_overlay.set(&"card_rows", rows)
	_overlay.set(&"card_chips", chips)
	_overlay.set(&"card_combo", combo)


func _process(delta: float) -> void:
	_t += delta
	_overlay.set(&"t", _t)
	if _t < ENTER:
		_ship.position = START.lerp(_home, ease(_t / ENTER, 0.4))
	elif _t >= _leave_at:
		_ship.position = _home.lerp(EXIT, ease(minf((_t - _leave_at) / LEAVE, 1.0), 2.2))
	else:
		_ship.position = _home + Vector2(0, sin(_t * 3.0) * 3.0)
	if _t >= _card_at:
		_hand_over()
	if _t >= _leave_at + LEAVE:
		_finish()


func _input(event: InputEvent) -> void:
	var pressed := (event is InputEventScreenTouch or event is InputEventMouseButton or event is InputEventKey) and event.is_pressed()
	if pressed and _t > SKIP_GUARD:
		get_viewport().set_input_as_handled()
		_finish()


func _hand_over() -> void:
	if _handed:
		return
	_handed = true
	if on_hand_over.is_valid():
		on_hand_over.call()


func _finish() -> void:
	if _done:
		return
	_done = true
	_hand_over()
	finished.emit()
	queue_free()
