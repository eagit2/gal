class_name UpgradePick
extends CanvasLayer
## Between-stage card pick: shows the rolled upgrades as cards and emits `picked`.
## Keyboard and gamepad move focus with the UI actions; touch and mouse tap a card.
## Cards stay disabled for a moment so a held fire button can't pick by accident.

signal picked(upgrade: UpgradeDef)

const ARM_DELAY := 0.5
const RARITY_NAMES: Array[String] = ["COMMON", "RARE", "EPIC"]
const RARITY_COLORS: Array[Color] = [Color(0.957, 0.89, 0.757), Color(0.4, 0.85, 1.0), Color(1.0, 0.55, 0.95)]
const CATEGORY_NAMES: Array[String] = ["PRIMARY", "SECONDARY", "DEFENSE", "UTILITY"]

var _choices: Array[UpgradeDef] = []

@onready var _cards: VBoxContainer = $Root/Cards


func _ready() -> void:
	visible = false


func open(choices: Array[UpgradeDef]) -> void:
	_choices = choices
	for child in _cards.get_children():
		child.queue_free()
	for i in choices.size():
		_cards.add_child(_make_card(choices[i], i))
	visible = true
	get_tree().create_timer(ARM_DELAY, false).timeout.connect(_arm)


func is_open() -> bool:
	return visible


## Picks card `index` (also used by tests and the smoke run).
func choose(index: int) -> void:
	if not visible or index < 0 or index >= _choices.size():
		return
	visible = false
	picked.emit(_choices[index])


func _arm() -> void:
	if not visible:
		return
	var first: Button = null
	for card: Button in _cards.get_children():
		if card.is_queued_for_deletion():
			continue
		card.disabled = false
		if first == null:
			first = card
	if first:
		first.grab_focus()


func _make_card(upgrade: UpgradeDef, index: int) -> Button:
	var card := Button.new()
	card.custom_minimum_size = Vector2(460, 150)
	card.disabled = true
	card.alignment = HORIZONTAL_ALIGNMENT_LEFT
	card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_theme_font_size_override(&"font_size", 20)
	var color := RARITY_COLORS[upgrade.rarity]
	card.add_theme_color_override(&"font_color", color)
	card.add_theme_color_override(&"font_focus_color", color)
	card.add_theme_color_override(&"font_hover_color", color)
	var owned := UpgradeSystem.stacks(GameState.owned, upgrade.id)
	var level := " (LV %d)" % (owned + 1) if upgrade.max_stacks > 1 else ""
	card.text = "%s%s\n%s · %s\n%s" % [upgrade.display_name.to_upper(), level, RARITY_NAMES[upgrade.rarity], CATEGORY_NAMES[upgrade.category], upgrade.description]
	card.pressed.connect(choose.bind(index))
	return card
