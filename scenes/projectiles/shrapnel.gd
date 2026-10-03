class_name Shrapnel
extends Bullet
## A small scrap piece a ScrapBall breaks into. Flies a short way and skips the enemy the ball hit.

## The enemy the ball hit; this piece passes over it.
var ignore: Node


func _on_area_entered(area: Area2D) -> void:
	if is_instance_valid(ignore) and (area.get_parent() == ignore or area.get_parent().get_parent() == ignore):
		return
	super(area)


func release() -> void:
	ignore = null
	super()
