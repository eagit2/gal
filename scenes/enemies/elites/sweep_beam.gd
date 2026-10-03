extends Node2D
## Sweeper's laser: points straight down (rotated by the trait). Mode 0 off, 1 aiming line
## (harmless), 2 firing (its hitbox costs a life).

func set_mode(mode: int) -> void:
	$Hitbox.monitoring = mode == 2
	$Visual.call("set_mode", mode)
