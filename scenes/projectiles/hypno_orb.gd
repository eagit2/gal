class_name HypnoOrb
extends Bullet
## Hypno Gun shot: a swirling orb. A regular enemy it hits takes no damage but is hypnotized
## (HypnoControl) for HypnoControl.BASE_TIME + the hypno_time stat seconds and turns on its own
## side. Elites, and enemies already hypnotized or in a bubble, just take the shot's damage.

var _hypno_time := HypnoControl.BASE_TIME
var _weapon_damage := 1


func configure(weapon: WeaponDef, stats: Dictionary) -> void:
	super(weapon, stats)
	rotation = 0.0
	_weapon_damage = damage
	_hypno_time = HypnoControl.BASE_TIME + float(stats[&"hypno_time"])


func _on_area_entered(area: Area2D) -> void:
	damage = 0 if _hypnotizes(area.get_parent()) else _weapon_damage
	super(area)


func _hypnotizes(target: Node) -> bool:
	var enemy := target as Enemy
	return HypnoControl.can_hypnotize(
		enemy != null and enemy.health().hp > 0,
		enemy != null and enemy.has_node(NodePath(HypnoControl.NODE_NAME)),
		enemy != null and enemy.has_node(NodePath(BubbleTrap.NODE_NAME)))


func _on_hit(hurtbox: Hurtbox) -> void:
	var enemy := hurtbox.get_parent() as Enemy
	if damage == 0 and enemy != null and not enemy.has_node(NodePath(HypnoControl.NODE_NAME)):
		var control := HypnoControl.new()
		control.name = HypnoControl.NODE_NAME
		control.duration = _hypno_time
		control.mode = HypnoControl.pick_mode(randf())
		enemy.add_child.call_deferred(control)
	super(hurtbox)
