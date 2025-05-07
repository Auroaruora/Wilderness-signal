class_name Character extends CharacterBody2D

signal moved_tiles(previous_position: Vector2i, new_position: Vector2i, player_instance: Character)

# Define enums for action states and movement directions
#region Enums
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
#endregion

#region Node References
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var inventory = $InventoryUI/InventoryDisplay/Inventory
@onready var attack_area = $player_hitbox
#endregion

#region Export Variables
@export var speed: float = 100.0
@export var acceleration: float = 800.0
@export var friction: float = 1000.0
@export var base_luminosity: int = 2
@export var map: TileMap
#endregion

#region State Variables
var current_direction: Direction = Direction.DOWN
var current_action_state: ActionState = ActionState.IDLE
var last_action_direction: Direction = Direction.DOWN
var current_tile_position: Vector2i
var is_blinking: bool = false
var blink_count: int = 0
var blink_max: int = 6
var blink_duration: float = 0.2
var blink_timer: Timer
var current_weapon = null
#endregion



#region Core Lifecycle Functions
func _ready() -> void:
	# Initialize default animations
	setup_action_handlers()
	play_idle_animation()
	#GameManager.register_player(self)
	GlobalData.load_player_state(self)
	$InventoryUI/InventoryDisplay.inventory = $InventoryUI/InventoryDisplay/Inventory
	print("Connected inventory to display")
	attack_area.area_entered.connect(on_attack_area_entered)

func _unhandled_input(event: InputEvent) -> void:
	# Handle action inputs
	if event.is_action_pressed("interact") and inventory.get_selected_item_name()=="axe":
		attempt_action("axe")
	if event.is_action_pressed("interact") and inventory.get_selected_item_name()=="pickaxe":
		attempt_action("pickaxe") 
		
func _physics_process(delta: float) -> void:
	# Check health status first - only process movement if alive
	var health_system = get_node_or_null("HealthSystem")
	if health_system and health_system.current_health <= 0:
		if current_action_state != ActionState.DEAD:
			die()
	
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
#endregion

#region Action System
class CharacterAction:
	var name: String
	var condition: Callable
	var action: Callable
	var animation_prefix: String
	
	func _init(p_name: String,p_action: Callable, p_animation_prefix: String):
		name = p_name
		action = p_action
		animation_prefix = p_animation_prefix

var action_handlers: Dictionary = {}

func setup_action_handlers() -> void:
	# Generic method to add actions more easily
	add_action(
		"axe",
		func(): print("axing action"),#attempt_tree_cut(),  # Action
		"axe_"  # Animation prefix
	)
	add_action(
		"hammer",
		func(): print("Hammering action"),  # This will be overridden by the tower
		"hammer_"  # Animation prefix
	)
	add_action(
		"pickaxe",
		func(): print("pickaxing action"),  # This will be overridden by the tower
		"pickaxe_"  # Animation prefix
	)

func add_action(action_name: String, action: Callable, animation_prefix: String) -> void:
	action_handlers[action_name] = CharacterAction.new(
		action_name,
		action,
		animation_prefix
	)

func attempt_action(action_name: String) -> void:
	# Check if action exists and can be performed
	if action_name in action_handlers:
		var action_data = action_handlers[action_name]
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

#d
#endregion

#region Movement System
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
#endregion

#region Animation System
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
			play_death_animation()

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

func play_death_animation() -> void:
	var animation_name: String = "death_" + get_direction_name()
	print("Attempting to play death animation: " + animation_name)
	print("Available animations: " + str(animated_sprite.sprite_frames.get_animation_names()))
	
	# Only play the animation if it's not already playing
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)
		
		# Connect to animation finished signal if not already connected
		if not animated_sprite.animation_finished.is_connected(_on_death_animation_finished):
			animated_sprite.animation_finished.connect(_on_death_animation_finished)

func _on_action_animation_finished() -> void:
	# Disconnect the signal
	animated_sprite.animation_finished.disconnect(_on_action_animation_finished)
	
	# Reset to idle state and maintain the last action direction
	current_action_state = ActionState.IDLE
	current_direction = last_action_direction
	play_idle_animation()

func _on_death_animation_finished() -> void:
	# Check if it was a death animation
	if animated_sprite.animation.begins_with("death_"):
		# Disconnect the signal to avoid repeated calls
		if animated_sprite.animation_finished.is_connected(_on_death_animation_finished):
			animated_sprite.animation_finished.disconnect(_on_death_animation_finished)
		
		print("Death animation completed, starting resurrection process")
		# Start resurrection after death animation finishes
		resurrect()

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
#endregion

#region Utility Functions
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
#endregion


#region Health and Hunger Management
func restore_health(amount: int) -> void:
	# Find the health system component
	var health_system = get_node_or_null("HealthSystem")
	
	# Only restore health if health system exists
	if health_system:
		# Calculate the new health, ensuring it doesn't exceed max health
		var new_health = min(
			health_system.current_health + amount, 
			health_system.max_health
		)
		
		# Update the current health
		health_system.current_health = new_health
		
		# Emit the health changed signal
		health_system.emit_signal("health_changed", new_health)
		
		print("Restored %d health. Current health: %d" % [amount, new_health])
	else:
		print("Cannot restore health: No HealthSystem found")

func restore_hunger(amount: int) -> void:
	# Find the hunger system component
	var hunger_system = get_node_or_null("HungerSystem")
	
	# Only restore hunger if hunger system exists
	if hunger_system:
		# Calculate the new hunger value, ensuring it doesn't exceed max hunger
		var new_hunger = min(
			hunger_system.current_hunger + amount, 
			hunger_system.max_hunger
		)
		
		# Update the current hunger
		hunger_system.current_hunger = new_hunger
		
		# Emit the hunger changed signal
		hunger_system.emit_signal("hunger_changed", new_hunger)
		
		print("Restored %d hunger. Current hunger: %d" % [amount, new_hunger])
	else:
		print("Cannot restore hunger: No HungerSystem found")
#endregion

#region Death and Resurrection System
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
	
	# Disable input processing
	set_process_unhandled_input(false)
	
	print("Character died")
	# The animation will be handled in handle_animations()

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
#endregion

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		for interactable in get_tree().get_nodes_in_group("interactable"):
			if interactable.player_in_range:
				interactable.interact()
				break

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if current_weapon:
			attack()
			current_weapon.attack()
				
func attack():
	attack_area.monitoring = true  # Activate hitbox for this frame
	await get_tree().create_timer(0.1).timeout  # Attack lasts 0.1 sec
	attack_area.monitoring = false
	
func on_attack_area_entered(area):
	if area.name == "enemy_hitbox":
		var bat = area.get_parent()
		if bat.has_method("take_damage"):
			print("Bat took damage")

func pickup_weapon(weapon):
	if current_weapon:
		drop_weapon(current_weapon)
	current_weapon = weapon
	if weapon.get_parent():
		weapon.get_parent().remove_child(weapon)
	$WeaponSocket.add_child(weapon)
	weapon.position = Vector2.ZERO
	weapon.remove_from_group("interactable")
	weapon.attached = true

func drop_weapon(weapon):
	if weapon.get_parent():
		weapon.get_parent().remove_child(weapon)
	#get_tree().current_scene.remove_child(weapon)
	weapon.global_position = global_position + Vector2(0, 50)
	# Do not allow swap between weapons after choosing one
	# weapon.add_to_group("interactable")
	current_weapon = null
	weapon.attached = false
