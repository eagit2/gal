extends Node2D
## Draws the hangar loadout on the player ship: the frame's hull sprite, and each equipped module's
## part at its slot, glowing brighter as the module levels up. Lives inside the `dusk_armada`
## child, so other styles never show it. Reads the Hangar autoload; gameplay never touches it.

const PARTS_DIR := "res://assets/art/dusk_armada/parts/%s.png"
const GLOW := preload("res://assets/art/dusk_armada/projectiles/glow_round.png")
const KIND_COLORS: Array[Color] = [Color("5fe06a"), Color("4fa6ff"), Color("ffd34f"), Color("b98bff")]
## Matches the 2x pixel scale of the ship sprite.
const PIXEL := 2.0

@export var hull: Sprite2D


func _ready() -> void:
	EventBus.hangar_changed.connect(rebuild)
	rebuild()


func rebuild() -> void:
	for child in get_children():
		child.queue_free()
	var catalog := Hangar.CATALOG
	var state := Hangar.state()
	var frame := Loadout.frame_of(catalog, state)
	if hull and frame.sprite:
		hull.texture = frame.sprite
	for slot in frame.slots:
		var def := Loadout.def_at(catalog, state, Loadout.in_slot(catalog, state, slot))
		if def == null or not ResourceLoader.exists(PARTS_DIR % def.part):
			continue
		var anchor: Vector2 = FrameDef.ANCHORS[slot] * PIXEL
		var level := Loadout.slot_level(catalog, state, slot)
		if level > 1:
			var glow := Sprite2D.new()
			glow.texture = GLOW
			glow.position = anchor
			glow.modulate = Color(KIND_COLORS[def.kind], 0.35 * (level - 1))
			glow.scale = Vector2.ONE * 0.6
			glow.material = CanvasItemMaterial.new()
			(glow.material as CanvasItemMaterial).blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			add_child(glow)
		var part := Sprite2D.new()
		part.texture = load(PARTS_DIR % def.part)
		part.position = anchor
		part.scale = Vector2.ONE * PIXEL
		part.flip_h = anchor.x < 0
		add_child(part)
