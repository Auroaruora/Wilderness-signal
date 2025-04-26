extends Entity
class_name TreeNode

@onready var tree_sprite = $TreeSprite
@onready var cut_tree_sprite = $TreePivot/CutTreeSprite
@onready var stump_sprite = $StumpSprite
@onready var tree_pivot = $TreePivot
@onready var explosion_particles = null
@export var pickable_wood_scene: PackedScene
@export var wood_resource: Resource

# Add a state variable to track if the tree has been cut
var is_tree_cut = false

func _ready():
	add_to_group("trees")
	# Initially, only show the standing tree
	tree_sprite.visible = true
	cut_tree_sprite.visible = false
	stump_sprite.visible = false

func _input(event):
	# Check for directional tree cutting
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_L:
				cut_tree("left")
			KEY_R:
				cut_tree("right")

func cut_tree(direction: String):
	# Check if the tree has already been cut
	if is_tree_cut:
		print("Tree is already cut!")
		return
	
	# Mark the tree as cut
	is_tree_cut = true
	
	# Hide the standing tree
	tree_sprite.visible = false
	
	# Show the stump and cut tree
	stump_sprite.visible = true
	cut_tree_sprite.visible = true
	
	# Determine tilt angle and wood drop direction
	var tilt_angle = 0
	var wood_drop_offset = Vector2.ZERO
	
	match direction:
		"left":
			tilt_angle = -55  # Tilt to the left
			wood_drop_offset = Vector2(-15, 10)  # Drop wood to the left
		"right":
			tilt_angle = 55   # Tilt to the right
			wood_drop_offset = Vector2(15, 10)  # Drop wood to the right
	
	# Animate the tree pivot
	var tween = create_tween()
	tween.tween_property(tree_pivot, "rotation_degrees", tilt_angle, 1.0)
	
	# Add a callback to drop wood items after the tween starts
	tween.tween_callback(func(): drop_wood_items(wood_drop_offset))
	
	# Add callback to explode tree
	tween.tween_callback(explode_tree)
	
	tween.play()

func drop_wood_items(offset: Vector2 = Vector2.ZERO):
	# Drop 3 wood items with directional randomization
	for i in range(3):
		var wood_item = pickable_wood_scene.instantiate()
		
		# Assign the wood resource to the pickable item
		wood_item.item_resource = wood_resource
		
		# Set the wood item's position with slight randomization
		var offset_x = offset.x + randf_range(-5, 5)  # Add some randomness to the offset
		var offset_y = offset.y + randf_range(-5, 5)
		wood_item.global_position = global_position + Vector2(offset_x, offset_y)
		
		# Add the wood item to the scene
		get_parent().add_child(wood_item)

func explode_tree():
	# Get the position of the tree before hiding it
	var global_pos = cut_tree_sprite.global_position
	var tree_size = cut_tree_sprite.texture.get_size()
	
	# Hide the cut tree
	cut_tree_sprite.visible = false
	
	# Create CPU particles at the tree's position
	explosion_particles = CPUParticles2D.new()
	add_child(explosion_particles)
	
	# Position particles at the tree's center
	explosion_particles.global_position = global_pos
	
	# Create a small square texture for the particles
	var square_texture = create_square_texture()
	explosion_particles.texture = square_texture
	
	# Configure particle behavior
	explosion_particles.amount = 40
	explosion_particles.lifetime = 0.8
	explosion_particles.one_shot = true
	explosion_particles.explosiveness = 1.0  # All particles emit at once
	explosion_particles.emitting = true
	
	# Set particle movement
	explosion_particles.direction = Vector2(0, -1)
	explosion_particles.spread = 180  # Full 360 degrees
	explosion_particles.initial_velocity_min = 15
	explosion_particles.initial_velocity_max = 40
	
	# No gravity for cleaner effect
	explosion_particles.gravity = Vector2(0, 0)
	
	# Set particle appearance
	explosion_particles.scale_amount_min = 0.3
	explosion_particles.scale_amount_max = 1
	
	# Start with wood-like color
	explosion_particles.color = Color(0.6, 0.4, 0.2)  # Brown wood color
	
	# Reduced damping so particles stay visible longer
	explosion_particles.damping_min = 10
	explosion_particles.damping_max = 20
	
	# Add scale curve to make particles shrink over time
	explosion_particles.scale_amount_curve = create_scale_curve()
	
	# Use another tween to fade out the white particles by changing the alpha
	var fade_tween = create_tween()
	fade_tween.tween_interval(0.1)  # Wait for color change to complete
	fade_tween.tween_property(explosion_particles, "color:a", 0.0, 0.3)  # Fade out
	
	# Clean up after particles finish
	await get_tree().create_timer(explosion_particles.lifetime + 0.5).timeout
	remove()
	explosion_particles.queue_free()

func create_square_texture():
	# Create a simple white square texture programmatically
	var image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color(1, 1, 1, 1))  # White square
	
	var texture = ImageTexture.create_from_image(image)
	return texture

# Create a curve that controls particle scale over lifetime
func create_scale_curve():
	var curve = Curve.new()
	curve.add_point(Vector2(0, 1))      # Start at full size
	curve.add_point(Vector2(0.7, 0.8))  # Maintain most of size for 70% of lifetime
	curve.add_point(Vector2(1, 0))      # Shrink to nothing at end
	
	var curve_texture = CurveTexture.new()
	curve_texture.curve = curve
	return curve_texture
