class_name CutsceneDef
extends Resource
## A mentor moment: after `deaths_to_trigger` deaths in a row on `stage_id`, a friendly ship flies in
## on the next restart, says `intro_line` and lends `grant_part` (fitted on `grant_mount`). When the
## stage is cleared it flies back, takes the part, leaves `reward_chip` and re-fits the replaced part.
## Plays once per save slot, the same on every difficulty.

@export var id: StringName
@export var stage_id: StringName
@export var deaths_to_trigger := 3
## Name over the text box.
@export var speaker := "ACE PILOT"
@export var intro_line := ""
@export var grant_part: StringName
@export var grant_mount: StringName = &"nose"
@export var reward_chip: StringName
## Take-back lines: clean clear on the first try with the part, clean clear after dying with it, any
## other clear.
@export var line_first_clean := ""
@export var line_retry_clean := ""
@export var line_fallback := ""
## Tint on the copy of the player's ship that plays the mentor.
@export var mentor_tint := Color(1.0, 0.75, 0.4)
## Enemy (roster id) that flies in to show off the lent weapon, and how many.
@export var demo_enemy: StringName = &"bee"
@export var demo_count := 3
