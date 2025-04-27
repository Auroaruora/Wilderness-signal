class_name Character extends CharacterBody2D

signal moved_tiles(previous_position: Vector2i, new_position: Vector2i, player_instance: Character)#

# Action Management
enum ActionState {
	IDLE,
	MOVING,
	ACTING,  # Generic acting state to replace multiple specific states
	DEAD
}

# Direction Management
enum Direction {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var inventory = $Inventory

@export var speed: float = 100.0
@export var acceleration: float = 800.0
@export var friction: float = 1000.0
@export var base_luminosity: int = 2#
@export var map: TileMap#

# Current state tracking
var current_direction: Direction = Direction.DOWN
var current_action_state: ActionState = ActionState.IDLE
var last_action_direction: Direction = Direction.DOWN
var current_tile_position: Vector2i#

# Generic Action Class
class CharacterAction:
	var name: String
	var condition: Callable
	var action: Callable
	var animation_prefix: String
	
	func _init(p_name: String, p_condition: Callable, p_action: Callable, p_animation_prefix: String):
		name = p_name
		condition = p_condition
		action = p_action
		animation_prefix = p_animation_prefix

# Action Handler
var action_handlers: Dictionary = {}

func _ready() -> void:
	# Initialize default animations
	setup_action_handlers()
	play_idle_animation()
	# Connect inventory to display
	if has_node("InventoryUI/InventoryDisplay") and has_node("Inventory"):
		$InventoryUI/InventoryDisplay.inventory = $Inventory
		print("Connected inventory to display")

		

func setup_action_handlers() -> void:
	# Generic method to add actions more easily
	add_action(
		"axe",
		func(): return inventory.has_item("axe"),  # Condition
		func(): attempt_tree_cut(),  # Action
		"axe_"  # Animation prefix
	)
	add_action(
		"hammer",
		func(): return true,  # Always available since we check elsewhere
		func(): print("Hammering action"),  # This will be overridden by the tower
		"hammer_"  # Animation prefix
	)
	# You can easily add more actions like this
	# add_action(
	# 	"fishing_rod", 
	# 	func(): return inventory.has_item("fishing_rod"),
	# 	func(): attempt_fishing(),
	# 	"fish_"
	# )

func add_action(action_name: String, condition: Callable, action: Callable, animation_prefix: String) -> void:
	action_handlers[action_name] = CharacterAction.new(
		action_name,
		condition,
		action,
		animation_prefix
	)

func _unhandled_input(event: InputEvent) -> void:
	# Handle action inputs
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		attempt_action("axe")  # You can extend this to multiple actions easily

func attempt_tree_cut() -> void:
	# Find the closest tree
	var nearby_trees = get_tree().get_nodes_in_group("trees")
	var closest_tree = null
	var min_distance = INF
	
	# Find the closest tree
	for tree in nearby_trees:
		var distance = global_position.distance_to(tree.global_position)
		if distance < min_distance:
			min_distance = distance
			closest_tree = tree
	
	# If a tree is found and is close enough
	if closest_tree and is_close_to_object(closest_tree.global_position):
		# Determine the cutting direction and character facing
		var relative_pos = closest_tree.global_position - global_position
		
		## Determine the most appropriate character animation direction
		#if abs(relative_pos.x) > abs(relative_pos.y):
			## Primarily horizontal movement
			#current_direction = Direction.LEFT if relative_pos.x < 0 else Direction.RIGHT
		#else:
			## Primarily vertical movement
			#current_direction = Direction.UP if relative_pos.y < 0 else Direction.DOWN
		
		# Determine 2D cutting direction for the tree
		var cut_direction = "left" if relative_pos.x < 0 else "right"
		closest_tree.cut_tree(cut_direction)

func _physics_process(delta: float) -> void:
	# Check health status first - only process movement if alive
	var health_system = get_node_or_null("HealthSystem")
	if health_system and health_system.current_health <= 0:
		die()
		return
	
	# Only allow movement when not in a blocking action state and alive
	if (current_action_state == ActionState.IDLE or current_action_state == ActionState.MOVING):
		handle_movement()
	
	handle_animations()
	move_and_slide()
	if map:#
		var new_tile_position = map.local_to_map(global_position)
		if new_tile_position != current_tile_position:
			moved_tiles.emit(current_tile_position, new_tile_position, self)
			current_tile_position = new_tile_position

func handle_movement() -> void:
	var direction: Vector2 = Input.get_vector("run_left", "run_right", "run_up", "run_down")
	velocity = direction * speed
	
	# Update current direction based on movement
	if direction != Vector2.ZERO:
		current_action_state = ActionState.MOVING
		update_direction(direction)
	else:
		current_action_state = ActionState.IDLE

func update_direction(direction: Vector2) -> void:
	if abs(direction.x) > abs(direction.y):
		current_direction = Direction.LEFT if direction.x < 0 else Direction.RIGHT
	else:
		current_direction = Direction.UP if direction.y < 0 else Direction.DOWN

func handle_animations() -> void:
	match current_action_state:
		ActionState.MOVING:
			play_movement_animation()
		ActionState.IDLE:
			play_idle_animation()
		# Removed specific action state handling
		ActionState.ACTING:
			# Acting animations handled separately
			pass
		ActionState.DEAD:
			# Death animation is handled in the die() function
			# Just make sure we don't override it with other animations
			pass

func play_movement_animation() -> void:
	var animation_name: String
	match current_direction:
		Direction.LEFT:
			animation_name = "run_left"
		Direction.RIGHT:
			animation_name = "run_right"
		Direction.UP:
			animation_name = "run_up"
		Direction.DOWN:
			animation_name = "run_down"
	animated_sprite.play(animation_name)

func play_idle_animation() -> void:
	var animation_name: String = "idle_"
	match current_direction:
		Direction.LEFT:
			animation_name += "left"
		Direction.RIGHT:
			animation_name += "right"
		Direction.UP:
			animation_name += "up"
		Direction.DOWN:
			animation_name += "down"
	animated_sprite.play(animation_name)

func attempt_action(action_name: String) -> void:
	# Check if action exists and can be performed
	if action_name in action_handlers:
		var action_data = action_handlers[action_name]
		
		# Check if action can be performed
		if action_data.condition.call():
			# Perform the generic action
			perform_generic_action(action_data)

func perform_generic_action(action_data) -> void:
	# Set to a generic acting state
	current_action_state = ActionState.ACTING
	
	# Store the current direction for the action
	last_action_direction = current_direction
	
	# Play action animation based on current direction
	var action_animation = get_directional_animation(action_data.animation_prefix)
	animated_sprite.play(action_animation)
	
	# Connect to animation finished signal only if not already connected
	if not animated_sprite.animation_finished.is_connected(_on_action_animation_finished):
		animated_sprite.animation_finished.connect(_on_action_animation_finished)

	
	# Perform the specific action
	action_data.action.call()
	
	# Optional: Add logging
	print(action_data.name + " used in " + get_direction_name())

func _on_action_animation_finished() -> void:
	# Disconnect the signal
	animated_sprite.animation_finished.disconnect(_on_action_animation_finished)
	
	# Reset to idle state and maintain the last action direction
	current_action_state = ActionState.IDLE
	current_direction = last_action_direction
	play_idle_animation()

func get_directional_animation(prefix: String) -> String:
	# Helper to get animation based on current direction
	match current_direction:
		Direction.UP:
			return prefix + "up"
		Direction.DOWN:
			return prefix + "down"
		Direction.LEFT:
			return prefix + "left"
		Direction.RIGHT:
			return prefix + "right"
	return prefix + "down"  # Default fallback

func get_direction_name() -> String:
	# Helper to get direction as string
	match current_direction:
		Direction.UP:
			return "up"
		Direction.DOWN:
			return "down"
		Direction.LEFT:
			return "left"
		Direction.RIGHT:
			return "right"
	return "down"  # Default fallback

func pickup_item(item):
	var success = inventory.add_item(item)
	inventory.print_inventory()
	return success

func is_close_to_object(object_position: Vector2, max_distance: float = 30.0) -> bool:
	var distance = global_position.distance_to(object_position)
	return distance <= max_distance

func get_interaction_direction(object_position: Vector2) -> String:
	var relative_pos = object_position - global_position
	
	# Only return left or right based on horizontal position
	return "left" if relative_pos.x < 0 else "right"

func get_luminosity():#
	return base_luminosity#
# Add this function to your Character class

func die() -> void:
	# Only die if not already dead
	if current_action_state == ActionState.DEAD:
		return
		
	# Set to dead state
	current_action_state = ActionState.DEAD
	
	# Log the death cause
	var health_system = get_node_or_null("HealthSystem")
	if health_system:
		print("Character died - Health: ", health_system.current_health)
	
	# Stop all movement
	velocity = Vector2.ZERO
	
	# Play death animation
	var animation_name = "death_" + get_direction_name()
	animated_sprite.play(animation_name)
	
	# Connect to the animation finished signal
	if not animated_sprite.animation_finished.is_connected(_on_death_animation_finished):
		animated_sprite.animation_finished.connect(_on_death_animation_finished)
	
	# Disable input processing
	set_process_unhandled_input(false)
	
	print("Character died")
	
	# Remove the timer-based resurrection - we'll use animation completion instead
	# Let the animation finish naturally before resurrecting
	
func _on_death_animation_finished() -> void:
	# Check if it was a death animation
	if animated_sprite.animation.begins_with("death_"):
		# Disconnect the signal to avoid repeated calls
		if animated_sprite.animation_finished.is_connected(_on_death_animation_finished):
			animated_sprite.animation_finished.disconnect(_on_death_animation_finished)
		
		print("Death animation completed, starting resurrection process")
		# Start resurrection after death animation finishes
		resurrect()


func resurrect() -> void:
	print("Character resurrected")
	
	# Reset health system first
	var health_system = get_node_or_null("HealthSystem")
	if health_system:
		health_system.current_health = health_system.max_health
		health_system.emit_signal("health_changed", health_system.current_health)

	# Reset hunger system
	var hunger_system = get_node_or_null("HungerSystem")
	if hunger_system:
		hunger_system.current_hunger = hunger_system.max_hunger
		hunger_system.emit_signal("hunger_changed", hunger_system.current_hunger)
	
	# Start blinking animation
	start_blinking_sequence()
	
# Keep these variables
var is_blinking: bool = false
var blink_timer: Timer
var blink_count: int = 0
var blink_max: int = 6  # Total number of blink cycles
var blink_duration: float = 0.2  # Duration of each blink state

func start_blinking_sequence() -> void:
	# Create the blink timer only when needed
	if not blink_timer:
		blink_timer = Timer.new()
		blink_timer.timeout.connect(_on_blink_timer_timeout)
		add_child(blink_timer)
	
	is_blinking = true
	blink_count = 0
	
	# Set the idle animation first before starting to blink
	current_action_state = ActionState.IDLE
	play_idle_animation()
	
	animated_sprite.visible = false  # Start invisible
	blink_timer.wait_time = blink_duration
	blink_timer.start()
	print("Blinking sequence started after resurrection")
	
func _on_blink_timer_timeout() -> void:
	if is_blinking:
		# Toggle visibility
		animated_sprite.visible = !animated_sprite.visible
		blink_count += 1
		
		# Check if blinking sequence is complete
		if blink_count >= blink_max * 2:  # Each cycle has 2 states (visible/invisible)
			print("Blinking sequence complete")
			is_blinking = false
			animated_sprite.visible = true
			blink_timer.stop()
			
			# Now that blinking is complete, finish the resurrection process
			finish_resurrection()
func finish_resurrection() -> void:
	# Reset state
	current_action_state = ActionState.IDLE
	
	# Enable input processing again
	set_process_unhandled_input(true)
	set_physics_process(true)
	
	# Play idle animation
	play_idle_animation()
	
	print("Character resurrection complete with blinking effect")
