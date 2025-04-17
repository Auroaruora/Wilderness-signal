class_name Character extends CharacterBody2D

# Action Management
enum ActionState {
	IDLE,
	MOVING,
	ACTING,  # Generic acting state to replace multiple specific states
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

# Current state tracking
var current_direction: Direction = Direction.DOWN
var current_action_state: ActionState = ActionState.IDLE
var last_action_direction: Direction = Direction.DOWN

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

func setup_action_handlers() -> void:
	# Generic method to add actions more easily
	add_action(
		"axe", 
		func(): return inventory.has_item("axe"),  # Condition
		func(): attempt_tree_cut(),  # Action
		"axe_"  # Animation prefix
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
		
		# Determine the most appropriate character animation direction
		if abs(relative_pos.x) > abs(relative_pos.y):
			# Primarily horizontal movement
			current_direction = Direction.LEFT if relative_pos.x < 0 else Direction.RIGHT
		else:
			# Primarily vertical movement
			current_direction = Direction.UP if relative_pos.y < 0 else Direction.DOWN
		
		# Determine 2D cutting direction for the tree
		var cut_direction = "left" if relative_pos.x < 0 else "right"
		closest_tree.cut_tree(cut_direction)

func _physics_process(delta: float) -> void:
	# Only allow movement when not in a blocking action state
	if current_action_state == ActionState.IDLE or current_action_state == ActionState.MOVING:
		handle_movement()
	
	handle_animations()
	move_and_slide()

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
	
	# Connect to animation finished signal
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

# Check if the character is close enough to interact with an object
func is_close_to_object(object_position: Vector2, max_distance: float = 20.0) -> bool:
	var distance = global_position.distance_to(object_position)
	return distance <= max_distance

# Modify the existing get_interaction_direction method
func get_interaction_direction(object_position: Vector2) -> String:
	var relative_pos = object_position - global_position
	
	# Only return left or right based on horizontal position
	return "left" if relative_pos.x < 0 else "right"
