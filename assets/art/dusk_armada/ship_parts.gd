extends Node2D
## Draws the hangar loadout on the player ship: the ship's hull sprite, and each fitted part's
## sprite at its mount: rank 2 adds a glow, rank 3 doubles the part. Lives inside the
## `dusk_armada` child, so other styles never show it. Reads the Hangar autoload (or a `preview`
## loadout for the store); gameplay never touches it.

const PARTS_DIR := "res://assets/art/dusk_armada/parts/%s.png"
const GLOW := preload("res://assets/art/dusk_armada/projectiles/glow_round.png")
const SLOT_COLORS := {&"weapon": Color("5fe06a"), &"shield": Color("b98bff"), &"power": Color("ffd34f"), &"bonus": Color("4fa6ff")}
## Matches the 2x pixel scale of the ship sprite.
const PIXEL := 2.0

@export var hull: Sprite2D
## A loadout to draw instead of the saved one (store previews). Set before adding to the tree.
var preview := {}


func _ready() -> void:
	if preview.is_empty():
		EventBus.hangar_changed.connect(rebuild)
	rebuild()


func rebuild() -> void:
	for child in get_children():
		child.queue_free()
	var catalog := Hangar.CATALOG
	var state := Hangar.state() if preview.is_empty() else preview
	var ship := Loadout.ship_of(catalog, state)
	if hull and ship.sprite:
		hull.texture = ship.sprite
	for mount in ship.mounts:
		var def := Loadout.part_at(catalog, state, mount)
		if def == null or not ResourceLoader.exists(PARTS_DIR % def.part):
			continue
		var anchor: Vector2 = ShipDef.ANCHORS[mount] * PIXEL
		var rank := Loadout.rank_of(state, def.id)
		if rank > 1:
			var glow := Sprite2D.new()
			glow.texture = GLOW
			glow.position = anchor
			glow.modulate = Color(SLOT_COLORS[def.slot()], 0.35 * (rank - 1))
			glow.scale = Vector2.ONE * (0.4 + 0.2 * rank)
			glow.material = CanvasItemMaterial.new()
			(glow.material as CanvasItemMaterial).blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			add_child(glow)
		# Rank 3 doubles the part: side by side on the nose and rear, stacked on the side mounts.
		var spread := Vector2(3, 0) if mount in [&"nose", &"rear"] else Vector2(0, 3)
		var offsets := [Vector2.ZERO] if rank < 3 else [-spread * PIXEL, spread * PIXEL]
		for offset: Vector2 in offsets:
			var part := Sprite2D.new()
			part.texture = load(PARTS_DIR % def.part)
			part.position = anchor + offset
			part.scale = Vector2.ONE * PIXEL
			part.flip_h = anchor.x < 0
			add_child(part)
