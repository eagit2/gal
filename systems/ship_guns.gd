class_name ShipGuns
extends RefCounted
## Which guns a ship fires: the nose weapon (or the basic gun when the nose is empty) plus any
## weapon fitted on a side or rear mount, each firing its own WeaponDef from that side of the ship.
## Pure functions so tests can call them directly.

const BASIC: WeaponDef = preload("res://data/weapons/basic.tres")
## Muzzle offset from the ship centre and shot direction (degrees from straight up) per mount.
const MUZZLES := {
	&"nose": [Vector2(0, -26), 0.0],
	&"left": [Vector2(-18, -8), -15.0],
	&"right": [Vector2(18, -8), 15.0],
	&"rear": [Vector2(0, 16), 0.0],
}


## [{"mount", "weapon"}] for every gun on the ship, nose first.
static func mounted(catalog: HangarCatalog, state: Dictionary) -> Array[Dictionary]:
	var guns: Array[Dictionary] = []
	for mount: StringName in MUZZLES:
		var part := Loadout.part_at(catalog, state, mount)
		var weapon: WeaponDef = part.weapon if part else null
		if mount == &"nose" and weapon == null:
			weapon = BASIC
		if weapon:
			guns.append({"mount": mount, "weapon": weapon})
	return guns


static func muzzle_offset(mount: StringName) -> Vector2:
	return MUZZLES.get(mount, MUZZLES[&"nose"])[0]


static func muzzle_angle(mount: StringName) -> float:
	return MUZZLES.get(mount, MUZZLES[&"nose"])[1]
