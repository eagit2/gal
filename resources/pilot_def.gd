class_name PilotDef
extends Resource
## A pilot picked in the hangar. Each brings one active power, fired with the power button and
## recharged over `cooldown` seconds. PilotPower (scenes/player/pilot_power.gd) runs it.

enum Power {
	OVERCLOCK,  ## `effects` for `duration` seconds
	BULWARK,  ## restore the shield and stay invulnerable for `duration` seconds
	PHASE_DASH,  ## dash `distance` px in the move direction, invulnerable for `duration` seconds
	NOVA,  ## clear enemy shots and deal `damage` to every enemy on screen
}

@export var id: StringName
@export var display_name: String
@export_multiline var bio: String
@export var cost: int = 0
@export var color: Color = Color.WHITE
@export var power: Power
@export var power_name: String
@export_multiline var power_text: String
@export var cooldown: float = 20.0
@export var duration: float = 0.0
@export var effects: Array[Dictionary] = []
@export var distance: float = 0.0
@export var damage: int = 0
