class_name HungerSystem extends Node

signal hunger_changed(value)

@export var max_hunger: float = 100.0
@export var current_hunger: float = 100.0
@export var hunger_depletion_rate: float = 0.5  # How much hunger depletes per second
@export var health_damage_when_starving: float = 0.2  # Damage per second when starving
#@export_group("Hunger Settings")
#@export var max_hunger: float = 100.0:
	#set(val):
		#max_hunger = val
		#emit_signal("hunger_changed", current_hunger)
#@export var current_hunger: float = 100.0:
	#set(val):
		#current_hunger = min(max_hunger, val)
		#emit_signal("hunger_changed", current_hunger)
#@export var hunger_depletion_rate: float = 0.5  # How much hunger depletes per second
#@export var health_damage_when_starving: float = 0.2  # Damage per second when starving

func _ready():
	call_deferred("emit_signal", "hunger_changed", current_hunger)

func _process(delta):
	# Decrease hunger over time
	current_hunger = max(0, current_hunger - hunger_depletion_rate * delta)
	emit_signal("hunger_changed", current_hunger)
	
	# If hunger is at 0, damage health
	if current_hunger <= 0 and get_parent().has_node("HealthSystem"):
		var health_system = get_parent().get_node("HealthSystem")
		health_system.take_damage(health_damage_when_starving * delta)

func add_hunger(amount: float) -> void:
	current_hunger = min(max_hunger, current_hunger + amount)
	emit_signal("hunger_changed", current_hunger)

func get_hunger_percentage() -> float:
	return (current_hunger / max_hunger) * 100.0
