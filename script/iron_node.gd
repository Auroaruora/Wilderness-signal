extends Entity
class_name RockNode

# References to the different sprite stages
@onready var rock_sprite_1 = $RockSprite1
@onready var rock_sprite_2 = $RockSprite2
@onready var rock_sprite_3 = $RockSprite3
@onready var rock_sprite_4 = $RockSprite4

# Export variables for configuration
@export var pickable_ore_scene: PackedScene
@export var ore_resource: Resource
@export var interaction_distance = 40.0

# State variables
var harvest_count = 0
var max_harvests = 4
var player_ref = null

func _ready():
	add_to_group("rocks")
	print("Rock initialized with harvest_count: ", harvest_count)
	# Initially, only show the first stage rock
	update_rock_appearance()
	
func update_rock_appearance():
	print("Updating rock appearance. Current harvest count: ", harvest_count)
	
	# Hide all sprites first
	rock_sprite_1.visible = false
	rock_sprite_2.visible = false
	rock_sprite_3.visible = false
	rock_sprite_4.visible = false
	
	# Show the appropriate sprite based on harvest count
	match harvest_count:
		0: 
			rock_sprite_1.visible = true
			print("Rock is showing appearance 1")
		1: 
			rock_sprite_2.visible = true
			print("Rock is showing appearance 2")
		2: 
			rock_sprite_3.visible = true
			print("Rock is showing appearance 3")
		3: 
			rock_sprite_4.visible = true
			print("Rock is showing appearance 4")
		_: 
			print("Rock is depleted")

func _on_interaction_area_body_entered(body):
	if body is Character:  # Using the class_name from your Character script
		player_ref = body
		print("Player entered interaction area. Player reference set.")

func _on_interaction_area_body_exited(body):
	if body is Character and player_ref == body:
		player_ref = null
		print("Player exited interaction area. Player reference cleared.")
		
func _unhandled_input(event):
	# Only process if player is in range and rock isn't fully harvested
	if player_ref and harvest_count < max_harvests and is_player_close():
		# Check specifically for the interact action
		if event.is_action_pressed("interact"):
			# Check if pickaxe is selected at the moment of interaction
			if player_ref.inventory.get_selected_item_name() == "pickaxe":
				print("Player attempting to mine rock with pickaxe")
				# Tell the player to perform the pickaxe action before harvesting
				player_ref.attempt_action("pickaxe")
				# Short delay to allow animation to start before harvesting
				await get_tree().create_timer(0.1).timeout
				harvest_rock()
				# Accept the input so it doesn't propagate
				get_viewport().set_input_as_handled()

func is_player_close() -> bool:
	var is_close = player_ref.is_close_to_object(global_position, interaction_distance)
	print("Checking player distance. Is player close: ", is_close)
	return is_close
	
func harvest_rock():
	print("Harvesting rock. Current harvest count: ", harvest_count)
	
	if harvest_count >= max_harvests:
		print("Rock is already fully harvested!")
		return
	
	# Increment harvest count
	harvest_count += 1
	print("Harvest count increased to: ", harvest_count)
	
	# Drop ore
	drop_ore_items()
	
	# Update appearance
	update_rock_appearance()
	
	# If this was the final harvest, remove the rock
	if harvest_count >= max_harvests:
		print("Rock has reached maximum harvests. Removing.")
		# Give a short delay before removing to show the final state
		await get_tree().create_timer(0.3).timeout
		remove()

func drop_ore_items(offset: Vector2 = Vector2.ZERO):
	print("Dropping ore item")
	# Always drop exactly 1 ore per harvest
	var ore_item = pickable_ore_scene.instantiate()
	
	# Assign the ore resource to the pickable item
	ore_item.item_resource = ore_resource
	
	# Set the ore item's position with slight randomization
	var offset_x = offset.x + randf_range(0, 20)
	var offset_y = offset.y + randf_range(0, 20)
	ore_item.global_position = global_position + Vector2(offset_x, offset_y)
	
	# Add the ore item to the scene
	get_parent().add_child(ore_item)
	print("Ore item added to scene")

# Save state when the game saves or the node is removed from scene
func save():
	print("Saving rock state. Harvest count: ", harvest_count)
	# Return a dictionary with the rock's state
	return {
		"position": {
			"x": position.x,
			"y": position.y
		},
		"harvest_count": harvest_count
	}

# Load state when the game loads or the node is added to scene
func load_state(state_data):
	if state_data.has("position"):
		position.x = state_data.position.x
		position.y = state_data.position.y
	
	if state_data.has("harvest_count"):
		harvest_count = state_data.harvest_count
		print("Loaded rock with harvest count: ", harvest_count)
		update_rock_appearance()
