class_name StatusDisplay extends Control

@onready var hunger_bar = $HungerBar
@onready var hunger_label = $HungerLabel
@onready var health_bar = $HealthBar
@onready var health_label = $HealthLabel

func _ready():
	# Wait for a frame to ensure parent setup is complete
	call_deferred("setup_status_systems")

func setup_status_systems():
	# Get the Character node (parent of InventoryUI)
	var character = get_parent().get_parent()
	
	# Setup Health System
	if not character.has_node("HealthSystem"):
		var health_system = HealthSystem.new()
		health_system.name = "HealthSystem"
		character.call_deferred("add_child", health_system)
		await get_tree().process_frame
	
	# Setup Hunger System
	if not character.has_node("HungerSystem"):
		var hunger_system = HungerSystem.new()
		hunger_system.name = "HungerSystem"
		character.call_deferred("add_child", hunger_system)
		await get_tree().process_frame
	
	# Now connect signals after systems are added
	var health_system = character.get_node("HealthSystem")
	health_system.health_changed.connect(_on_health_changed)
	_on_health_changed(health_system.current_health)
	
	var hunger_system = character.get_node("HungerSystem")
	hunger_system.hunger_changed.connect(_on_hunger_changed)
	_on_hunger_changed(hunger_system.current_hunger)

func _on_hunger_changed(value):
	hunger_bar.value = value

func _on_health_changed(value):
	health_bar.value = value
