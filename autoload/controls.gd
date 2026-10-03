extends Node
## Registers input actions for keyboard and gamepad. Touch is handled by the player directly.

const KEYS := {
	"move_left": [KEY_LEFT, KEY_A],
	"move_right": [KEY_RIGHT, KEY_D],
	"move_up": [KEY_UP, KEY_W],
	"move_down": [KEY_DOWN, KEY_S],
	"fire": [KEY_SPACE, KEY_Z, KEY_J],
	"special": [KEY_C, KEY_L],
	"pause": [KEY_ESCAPE, KEY_P],
	"mute": [KEY_M],
	"power": [KEY_SHIFT, KEY_X, KEY_K],
	"debug_style": [KEY_F2],
}
const PAD_BUTTONS := {
	"move_left": [JOY_BUTTON_DPAD_LEFT],
	"move_right": [JOY_BUTTON_DPAD_RIGHT],
	"move_up": [JOY_BUTTON_DPAD_UP],
	"move_down": [JOY_BUTTON_DPAD_DOWN],
	"fire": [JOY_BUTTON_A],
	"special": [JOY_BUTTON_Y],
	"pause": [JOY_BUTTON_START],
	"power": [JOY_BUTTON_B, JOY_BUTTON_X],
}
const PAD_AXES := {
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
	"move_up": [JOY_AXIS_LEFT_Y, -1.0],
	"move_down": [JOY_AXIS_LEFT_Y, 1.0],
}


func _ready() -> void:
	for action: String in KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.25)
		for key: Key in KEYS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
		for button: JoyButton in PAD_BUTTONS.get(action, []):
			var event := InputEventJoypadButton.new()
			event.button_index = button
			InputMap.action_add_event(action, event)
		if PAD_AXES.has(action):
			var event := InputEventJoypadMotion.new()
			event.axis = PAD_AXES[action][0]
			event.axis_value = PAD_AXES[action][1]
			InputMap.action_add_event(action, event)
	# Menus navigate with the ui_* actions; add the game's keys so WASD and Z/J work there too.
	for pair: Array in [["ui_up", KEY_W], ["ui_down", KEY_S], ["ui_left", KEY_A], ["ui_right", KEY_D], ["ui_accept", KEY_Z], ["ui_accept", KEY_J]]:
		var event := InputEventKey.new()
		event.physical_keycode = pair[1]
		InputMap.action_add_event(pair[0], event)
