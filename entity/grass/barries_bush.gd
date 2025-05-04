extends Entity
class_name HarvestedBarriesBush

# References to the different sprite stages
@onready var regular_bush = $RegularBarriesBush
@onready var harvested_bush = $HarvestedBarriesBush

# Export variables for configuration
@export var pickable_berry_scene: PackedScene
@export var berry_resource: Resource
@export var interaction_distance = 40.0
@export var regrow_time = 300.0  # Time in seconds for bush to regrow berries (5 minutes default)

# State variables
var is_harvested = false
var regrow_timer = 0.0
var player_ref = null

func _ready():
	add_to_group("bushes")
	print("Berry bush initialized with harvested state: ", is_harvested)
	update_bush_appearance()

func _process(delta):
	# Handle regrowth timer if the bush is harvested
	if is_harvested:
		regrow_timer += delta
		if regrow_timer >= regrow_time:
			regrow_berries()

func update_bush_appearance():
	print("Updating bush appearance. Is harvested: ", is_harvested)
	
	# Show the appropriate sprite based on harvested state
	regular_bush.visible = !is_harvested
	harvested_bush.visible = is_harvested
	print("Bush is showing " + ("harvested" if is_harvested else "regular") + " appearance")

func _on_interaction_area_body_entered(body):
	if body is Character:  # Using the class_name from your Character script
		player_ref = body
		print("Player entered interaction area. Player reference set.")

func _on_interaction_area_body_exited(body):
	if body is Character and player_ref == body:
		player_ref = null
		print("Player exited interaction area. Player reference cleared.")
		
func _unhandled_input(event):
	# Only process if player is in range and bush has berries
	if player_ref and !is_harvested and is_player_close():
		# Check specifically for the interact action
		if event.is_action_pressed("interact"):
			print("Player attempting to harvest bush")
			harvest_bush()
			# Accept the input so it doesn't propagate
			get_viewport().set_input_as_handled()

func is_player_close() -> bool:
	var is_close = player_ref.is_close_to_object(global_position, interaction_distance)
	#print("Checking player distance. Is player close: ", is_close)
	return is_close
	
func harvest_bush():
	print("Harvesting bush.")
	
	if is_harvested:
		print("Bush is already harvested!")
		return
	
	# Set harvested state
	is_harvested = true
	regrow_timer = 0.0
	print("Bush has been harvested")
	
	# Drop berries
	drop_berry_items()
	
	# Update appearance
	update_bush_appearance()

func regrow_berries():
	print("Bush is regrowing berries")
	is_harvested = false
	regrow_timer = 0.0
	update_bush_appearance()

func drop_berry_items(offset: Vector2 = Vector2.ZERO):
	print("Dropping berry items")
	# Drop 1-3 berries per harvest
	var berry_count = randi_range(3, 5)
	
	for i in berry_count:
		var berry_item = pickable_berry_scene.instantiate()
		
		# Assign the berry resource to the pickable item
		berry_item.item_resource = berry_resource
		
		# Set the berry item's position with randomization
		var offset_x = offset.x + randf_range(-20, 20)
		var offset_y = offset.y + randf_range(-20, 20)
		berry_item.global_position = global_position + Vector2(offset_x, offset_y)
		
		# Add the berry item to the scene
		get_parent().add_child(berry_item)
	
	print("Dropped", berry_count, "berry items")

# Save state when the game saves or the node is removed from scene
func save():
	print("Saving bush state. Is harvested: ", is_harvested)
	# Return a dictionary with the bush's state
	return {
		"position": {
			"x": position.x,
			"y": position.y
		},
		"is_harvested": is_harvested,
		"regrow_timer": regrow_timer
	}

# Load state when the game loads or the node is added to scene
func load_state(state_data):
	if state_data.has("position"):
		position.x = state_data.position.x
		position.y = state_data.position.y
	
	if state_data.has("is_harvested"):
		is_harvested = state_data.is_harvested
		print("Loaded bush with harvested state: ", is_harvested)
	
	if state_data.has("regrow_timer"):
		regrow_timer = state_data.regrow_timer
		print("Loaded bush with regrow timer: ", regrow_timer)
		
	update_bush_appearance()
