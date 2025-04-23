class_name HealthSystem extends Node

signal health_changed(value)

@export var max_health: float = 100.0
@export var current_health: float = 100.0

func _ready():
	call_deferred("emit_signal", "health_changed", current_health)

func add_health(amount: float) -> void:
	current_health = min(max_health, current_health + amount)
	emit_signal("health_changed", current_health)

func take_damage(amount: float) -> void:
	current_health = max(0, current_health - amount)
	emit_signal("health_changed", current_health)
	
	if current_health <= 0:
		die()

func get_health_percentage() -> float:
	return (current_health / max_health) * 100.0
	
func die():
	# Override this in specific implementations
	print("Entity died")
