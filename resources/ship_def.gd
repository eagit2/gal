class_name ShipDef
extends Resource
## A ship: how many parts of each slot type it carries and the mounts they sit on. The weapon goes
## on the nose; every other part goes on a side or rear mount the player picks, and the mount
## changes what it does (HangarCatalog.placement).

## Mount anchors on the 1x player sprite, relative to its center.
## Parts stick out past the hull edge so the loadout reads at a glance.
const ANCHORS := {&"nose": Vector2(0, -12), &"left": Vector2(-11, 3), &"rear": Vector2(0, 11), &"right": Vector2(11, 3)}

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
## Parts allowed per slot type: weapon, shield, power, bonus.
@export var slots := {&"weapon": 1, &"shield": 1, &"power": 1, &"bonus": 1}
## Mounts in display order. "nose" takes weapons only; the rest take any other part.
@export var mounts: Array[StringName] = [&"nose", &"left", &"rear", &"right"]
## Player sprite (assets/art/dusk_armada/player*.png).
@export var sprite: Texture2D
## Blueprint tree nodes (data/hangar/tree/<ship>/).
@export var tree: Array[TreeNodeDef] = []


func node(id: StringName) -> TreeNodeDef:
	for n in tree:
		if n.id == id:
			return n
	return null


func accepts(mount: StringName, part: PartDef) -> bool:
	return mount in mounts and (mount == &"nose") == (part.category == PartDef.Category.WEAPON)
