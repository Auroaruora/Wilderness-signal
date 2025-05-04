extends CharacterBody2D

class_name Butterfly

# Configuration parameters
@export var min_distance: float = 70.0  # Minimum distance to maintain from player
@export var max_distance: float = 150.0  # Maximum distance to lead ahead
@export var base_speed: float = 80.0  # Base speed when at ideal distance
@export var max_speed: float = 180.0  # Maximum speed when player is close
@export var catch_up_speed: float = 220.0  # Speed when player moves away from entrance
@export var arrive_distance: float = 20.0  # Distance to consider "arrived" at target
@export var smooth_factor: float = 0.1  # Lower = smoother movement, higher = more responsive
@export var wobble_amount: float = 15.0  # How much to wobble when flying
@export var wobble_speed: float = 2.0  # Speed of the wobble
@export var debug: bool = false  # Enable/disable debug messages

# References to other nodes
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# State variables
var player: CharacterBody2D = null
var entrance: Area2D = null
var state: String = "leading"  # leading, arrived
var frame_count: int = 0
var target_velocity: Vector2 = Vector2.ZERO
var wobble_time: float = 0.0
var last_player_pos: Vector2 = Vector2.ZERO
var last_player_distance_to_entrance: float = 0.0
var player_is_moving: bool = true
var player_moving_away: bool = false
var hover_position: Vector2 = Vector2.ZERO
var hover_offset: Vector2 = Vector2.ZERO

func _ready():
	debug_print("_ready() called")
	
	# Find player and entrance in the scene
	player = get_tree().get_first_node_in_group("player")
	entrance = get_tree().get_first_node_in_group("entrance")
	
	debug_print("Player reference: " + str(player))
	debug_print("Entrance reference: " + str(entrance))
	
	if player and entrance:
		# Store initial player position and distance
		last_player_pos = player.global_position
		last_player_distance_to_entrance = player.global_position.distance_to(entrance.global_position)
		hover_position = global_position
		
		# Play animation
		animated_sprite.play("flutter")
		debug_print("Animation started, state set to leading")
	else:
		push_error("Butterfly: Player or entrance not found in scene")
		debug_print("ERROR: Player or entrance not found")

func _physics_process(delta):
	frame_count += 1
	wobble_time += delta
	
	# Only print debug every 60 frames to avoid spam
	var should_debug = debug && (frame_count % 60 == 0)
	
	if not player or not entrance:
		if should_debug:
			debug_print("Player or entrance missing, returning")
		return
	
	# Check if player is moving
	var player_moved = last_player_pos.distance_to(player.global_position) > 1.0
	
	# Check if player is moving away from entrance
	var current_distance_to_entrance = player.global_position.distance_to(entrance.global_position)
	player_moving_away = current_distance_to_entrance > last_player_distance_to_entrance + 1.0
	
	# Update tracking variables
	last_player_pos = player.global_position
	last_player_distance_to_entrance = current_distance_to_entrance
	
	# If player hasn't moved for a few frames, consider them stopped
	if player_moved:
		player_is_moving = true
		hover_position = global_position  # Update hover position while moving
	else:
		# Player is not moving, we'll hover in place
		if player_is_moving:  # Just stopped
			player_is_moving = false
			hover_position = global_position
	
	if should_debug:
		debug_print("Current state: " + state)
		debug_print("Player is moving: " + str(player_is_moving))
		debug_print("Player moving away from entrance: " + str(player_moving_away))
		debug_print("Distance to player: " + str(global_position.distance_to(player.global_position)))
		debug_print("Distance to entrance: " + str(global_position.distance_to(entrance.global_position)))
	
	match state:
		"leading":
			# Check if we've reached the entrance
			var distance_to_entrance = global_position.distance_to(entrance.global_position)
			
			if distance_to_entrance < arrive_distance:
				debug_print("ARRIVED at entrance! Distance: " + str(distance_to_entrance))
				state = "arrived"
				var tween = create_tween()
				tween.tween_property(animated_sprite, "modulate:a", 0.0, 1.0)
				tween.tween_callback(queue_free)
				return
			
			# Natural butterfly movement
			move_butterfly_naturally(delta)
			
		"arrived":
			if should_debug:
				debug_print("In arrived state, waiting for despawn")

func move_butterfly_naturally(delta):
	# Get direction to entrance
	var dir_to_entrance = (entrance.global_position - player.global_position).normalized()
	
	# Current distances
	var distance_to_player = global_position.distance_to(player.global_position)
	var distance_to_entrance = global_position.distance_to(entrance.global_position)
	var player_distance_to_entrance = player.global_position.distance_to(entrance.global_position)
	
	# Calculate target position based on player movement
	var target_pos: Vector2
	var current_speed: float
	
	if player_moving_away:
		# Player is moving away from entrance - move quickly to get in front of them
		# Position ourselves between player and entrance to guide them back
		target_pos = player.global_position + (dir_to_entrance * min_distance)
		current_speed = catch_up_speed
		
		debug_print("Player moving away - trying to get back in front")
	elif player_is_moving:
		# Player is moving - lead them toward the entrance
		# Calculate ideal position ahead of player toward entrance
		var ideal_distance = clamp(distance_to_player, min_distance, max_distance)
		
		# If player is far from entrance, get closer to them
		if player_distance_to_entrance > 200.0:
			ideal_distance = min_distance * 1.2
		
		target_pos = player.global_position + (dir_to_entrance * ideal_distance)
		
		# Adjust speed based on distance to player
		# Closer = faster to maintain proper leading distance
		var speed_factor = remap(distance_to_player, min_distance * 0.5, max_distance, 1.0, 0.5)
		speed_factor = clamp(speed_factor, 0.5, 1.0)
		current_speed = lerp(base_speed, max_speed, speed_factor)
		
		debug_print("Player moving normally - leading toward entrance")
	else:
		# Player isn't moving - hover in place with a small random movement
		hover_offset = Vector2(
			sin(wobble_time * wobble_speed) * wobble_amount * 1.5,
			cos(wobble_time * wobble_speed * 0.8) * wobble_amount
		)
		
		target_pos = hover_position + hover_offset
		current_speed = base_speed * 0.5
		
		debug_print("Player not moving - hovering")
	
	# Get direction to target
	var dir_to_target = (target_pos - global_position).normalized()
	
	# Add natural wobble to movement
	var wobble = Vector2(
		sin(wobble_time * wobble_speed * 1.5) * wobble_amount,
		cos(wobble_time * wobble_speed) * wobble_amount
	)
	
	# Calculate desired velocity with wobble
	var desired_velocity = dir_to_target * current_speed
	if player_is_moving:
		desired_velocity += wobble  # Add wobble only when moving
	
	# If we're too far from player, move faster to catch up
	if distance_to_player > max_distance * 1.5:
		desired_velocity = (player.global_position - global_position).normalized() * catch_up_speed
		debug_print("Too far from player - catching up!")
	
	# Smoothly transition to the desired velocity
	# Fixed ternary operator syntax for GDScript
	var smooth = smooth_factor * 0.5 if not player_is_moving else smooth_factor
	target_velocity = target_velocity.lerp(desired_velocity, smooth)
	
	# Set velocity and flip sprite direction
	velocity = target_velocity
	
	# Flip sprite based on movement direction
	if velocity.x < -5.0:
		animated_sprite.flip_h = true
	elif velocity.x > 5.0:
		animated_sprite.flip_h = false
	
	# Move the butterfly
	move_and_slide()

func debug_print(message):
	if debug:
		print("[Butterfly] " + message)
