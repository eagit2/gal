extends Hurtbox
## Armor plate on a Plated enemy's front. Takes shots for the enemy (it has its own Health) and
## breaks off when that runs out.


func _ready() -> void:
	($Health as Health).died.connect(_on_broken)


func _on_broken() -> void:
	EventBus.elite_trait_broken.emit(global_position)
	queue_free()
