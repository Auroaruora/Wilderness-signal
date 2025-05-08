# ItemPickup.gd
extends Area2D
class_name ItemPickup

@export var item_resource: Resource
@export var float_height: float = 5.0   # How high the item floats in pixels
@export var float_speed: float = 2.0    # Speed of the floating animation
@export var glow_intensity: float = 0.3 # Intensity of the glow effect
@export var fly_speed: float = 50.0    # Speed of flying towards player in pixels/second

@onready var sprite = $Sprite2D
@onready var original_y: float
@onready var is_flying: bool = false
@onready var target: Node2D = null

func _ready():
	# Set the sprite's texture from the resource
	if item_resource and "texture" in item_resource:
		sprite.texture = item_resource.texture
	
	# Store the original y position for the floating animation
	original_y = sprite.position.y

func _process(delta):
	if is_flying and target:
		process_flying_animation(delta)
	else:
		process_idle_animation(delta)

func process_idle_animation(delta):
	# Handle floating animation
	var t = Time.get_ticks_msec() / 1000.0 * float_speed
	sprite.position.y = original_y + sin(t) * float_height
	
	# Handle glowing effect
	var glow_factor = 1.0 + (sin(t * 0.75) * 0.5 + 0.5) * glow_intensity
	sprite.modulate = Color(glow_factor, glow_factor, glow_factor, 1.0)

func process_flying_animation(delta):
	# Calculate direction and distance to target
	var direction = global_position.direction_to(target.global_position)
	var distance = global_position.distance_to(target.global_position)
	
	# Get the initial distance if this is the first frame of flying
	if not has_meta("initial_distance"):
		set_meta("initial_distance", distance)
	
	var initial_distance = get_meta("initial_distance")
	
	# Move toward target
	global_position += direction * fly_speed * delta
	
	# Non-linear scaling that accelerates as we get closer
	var min_scale = 0.2  # Minimum scale (won't shrink smaller than this)
	var relative_distance = distance / initial_distance
	
	# Use a quadratic or cubic formula for non-linear scaling
	# This will make it shrink slowly at first, then more rapidly as it gets closer
	var scale_factor = min_scale + (1.0 - min_scale) * (relative_distance * relative_distance)
	
	# Alternative cubic formula for even more pronounced effect:
	# var scale_factor = min_scale + (1.0 - min_scale) * pow(relative_distance, 3)
	
	scale = Vector2(scale_factor, scale_factor)
	
	# Increase glow while flying
	sprite.modulate = Color(1 + glow_intensity, 1 + glow_intensity, 1 + glow_intensity, 1)
	
	# Remove when we're close enough
	if distance < 10:
		queue_free()

func _on_body_entered(body):
	if body.has_method("pickup_item") and not is_flying:
		if body.pickup_item(item_resource):
			start_flying_animation(body)

func start_flying_animation(player_body):
	# Enable flying mode
	is_flying = true
	
	# Set the target to follow
	target = player_body
	
	# Disable collision
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	if has_method("on_item_picked_up"):
		call("on_item_picked_up")
