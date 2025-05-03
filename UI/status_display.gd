class_name StatusDisplay extends Control
# Add these exports for testing
@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var max_hunger: float = 100.0
@export var current_hunger: float = 100.0
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
	
	# Setup Health System and pass the exported values
	if not character.has_node("HealthSystem"):
		var health_system = HealthSystem.new()
		health_system.name = "HealthSystem"
		health_system.max_health = max_health
		# Use saved health value if available, otherwise use exported value
		health_system.current_health = GlobalData.player_health if GlobalData.player_health > 0 else current_health
		character.call_deferred("add_child", health_system)
		await get_tree().process_frame
	else:
		# Update existing system with saved values
		var health_system = character.get_node("HealthSystem")
		health_system.max_health = max_health
		health_system.current_health = GlobalData.player_health if GlobalData.player_health > 0 else health_system.current_health
	
	# Setup Hunger System and pass the exported values
	if not character.has_node("HungerSystem"):
		var hunger_system = HungerSystem.new()
		hunger_system.name = "HungerSystem"
		hunger_system.max_hunger = max_hunger
		# Use saved hunger value if available, otherwise use exported value
		hunger_system.current_hunger = GlobalData.player_hunger if GlobalData.player_hunger > 0 else current_hunger
		character.call_deferred("add_child", hunger_system)
		await get_tree().process_frame
	else:
		# Update existing system with saved values
		var hunger_system = character.get_node("HungerSystem")
		hunger_system.max_hunger = max_hunger
		hunger_system.current_hunger = GlobalData.player_hunger if GlobalData.player_hunger > 0 else hunger_system.current_hunger
	
	# Ensure a frame has passed to avoid potential timing issues
	await get_tree().process_frame
	
	# Now connect signals after systems are added and values are set
	var health_system = character.get_node("HealthSystem")
	health_system.health_changed.connect(_on_health_changed)
	_on_health_changed(health_system.current_health)
	print("Health loaded: ", health_system.current_health)
	
	var hunger_system = character.get_node("HungerSystem")
	hunger_system.hunger_changed.connect(_on_hunger_changed)
	_on_hunger_changed(hunger_system.current_hunger)
	print("Hunger loaded: ", hunger_system.current_hunger)

func _on_hunger_changed(value):
	hunger_bar.value = value
	
func _on_health_changed(value):
	health_bar.value = value
