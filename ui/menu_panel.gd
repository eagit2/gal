class_name MenuPanel
extends Control
## Full-screen dimmed overlay with a centered column of buttons. Menus extend it and refill `box`;
## Escape / back calls `_on_cancel` (by default emits `closed`, and the owner frees the panel).

signal closed()

var box := VBoxContainer.new()


func _init() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.08, 0.86)
	dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(center)
	box.custom_minimum_size.x = 440
	box.add_theme_constant_override(&"separation", 14)
	center.add_child(box)


func clear() -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()


func add_label(text: String, size := 16) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override(&"font_size", size)
	box.add_child(label)
	return label


func add_button(text: String, action: Callable, disabled := false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 56
	button.disabled = disabled
	button.pressed.connect(action)
	box.add_child(button)
	return button


func focus_first() -> void:
	for child in box.get_children():
		if child is Button and not (child as Button).disabled:
			(child as Button).grab_focus()
			return


## Opens `panel` in place of this one's buttons and brings them back when it closes.
func open(panel: MenuPanel) -> void:
	box.visible = false
	add_child(panel)
	panel.closed.connect(func() -> void:
		panel.queue_free()
		box.visible = true
		focus_first())


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_cancel()


func _on_cancel() -> void:
	closed.emit()
