class_name ShipDef
extends Resource
## A ship: how many parts of each slot type it carries and the mounts they sit on. The nose takes a
## weapon; the side and rear mounts take any part (a second weapon too), and the mount changes what
## it does (HangarCatalog.placement). Ships after the first unlock by clearing a stage.

## Mount anchors on the 1x player sprite, relative to its center.
## Parts stick out past the hull edge so the loadout reads at a glance.
const ANCHORS := {&"nose": Vector2(0, -12), &"left": Vector2(-11, 3), &"rear": Vector2(0, 11), &"right": Vector2(11, 3)}

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
## Parts allowed per slot type: weapon, shield, engine, extra.
@export var slots := {&"weapon": 2, &"shield": 1, &"engine": 1, &"extra": 2}
## Mounts in display order. "nose" takes weapons only; the rest take any part but chips.
@export var mounts: Array[StringName] = [&"nose", &"left", &"rear", &"right"]
## Player sprite (assets/art/dusk_armada/player*.png).
@export var sprite: Texture2D
## Skill tree nodes (data/hangar/tree/<ship>/).
@export var tree: Array[TreeNodeDef] = []
## Stage to clear to unlock the ship (empty = open from the start), and how the menu says it.
@export var unlock_stage: StringName
@export var unlock_text: String


func node(id: StringName) -> TreeNodeDef:
	for n in tree:
		if n.id == id:
			return n
	return null


func accepts(mount: StringName, part: PartDef) -> bool:
	if not mount in mounts or part.category == PartDef.Category.CHIP:
		return false
	return mount != &"nose" or part.category == PartDef.Category.WEAPON
