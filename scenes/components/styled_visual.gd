class_name StyledVisual
extends Node2D
## Holds one child per art style, named by ThemeDef.id, and shows the active one.
## Vector themes with no dedicated child get a glowing wireframe generated from the base child's polygons.

@export var neon_color := Color(1, 0.25, 0.85)
var _wireframe: Node2D


func _ready() -> void:
	StyleDirector.style_changed.connect(apply_theme)
	apply_theme(StyleDirector.current)


func apply_theme(theme: ThemeDef) -> void:
	var shown: Node = get_node_or_null(NodePath(theme.id))
	if shown == null and theme.family == &"vector":
		shown = _get_wireframe()
	if shown == null:
		shown = get_node_or_null(NodePath(StyleDirector.BASE_THEME))
	for child in get_children():
		if child is CanvasItem:
			child.visible = child == shown
	if _wireframe and shown == _wireframe:
		_wireframe.modulate = theme.wire_tint


func _get_wireframe() -> Node2D:
	if _wireframe:
		return _wireframe
	_wireframe = Node2D.new()
	_wireframe.name = "Wireframe"
	var source := get_node_or_null(NodePath(StyleDirector.BASE_THEME))
	if source:
		for poly: Polygon2D in source.find_children("*", "Polygon2D", true, false):
			# Wide translucent line for glow, thin bright line on top.
			for pass_spec in [[6.0, 0.22], [2.0, 1.0]]:
				var line := Line2D.new()
				line.points = poly.transform * poly.polygon
				line.closed = true
				line.width = pass_spec[0]
				line.default_color = Color(neon_color, pass_spec[1])
				line.joint_mode = Line2D.LINE_JOINT_ROUND
				_wireframe.add_child(line)
	add_child(_wireframe)
	return _wireframe
