class_name RepairableTower extends StaticBody2D

@export var item_resource: Item = null
# Two sprites for different tower states
@onready var broken_sprite = $BrokenSprite
@onready var repaired_sprite = $RepairedSprite
@onready var interaction_area = $InteractionArea
@onready var message = $message

@export var iron_required = 3
@export var stone_required = 10
@export var wood_required = 30
@export var antenna_required = 1

@export var interaction_distance = 40.0

var is_broken = true
var player_ref = null
var win_screen = null

func _ready():
	# Set initial state
	broken_sprite.visible = true
	repaired_sprite.visible = false
	message.visible = false
	create_win_screen()

func _process(delta):
	# Check for player input when in range
	if player_ref and Input.is_action_just_pressed("interact") and is_broken:
		if is_player_close():
			attempt_repair()

func is_player_close() -> bool:
	return player_ref.is_close_to_object(global_position, interaction_distance)

func attempt_repair():
	# Check if player has all required materials
	if player_ref.inventory.get_stack_count("iron") >= iron_required and player_ref.inventory.get_stack_count("stone") >= stone_required and player_ref.inventory.get_stack_count("wood") >= wood_required and player_ref.inventory.get_stack_count("antenna") >= antenna_required:
		# Modify the action handling to work with the existing attempt_action method
		player_ref.add_action(
			"tower_repair",  # Unique action name
			func(): consume_materials_and_repair(),  # Changed function name
			"hammer_"  # Animation prefix
		)
		
		# Determine facing direction relative to tower
		var direction = player_ref.get_interaction_direction(global_position)
		if direction == "left":
			player_ref.current_direction = player_ref.Direction.LEFT
		else:
			player_ref.current_direction = player_ref.Direction.RIGHT
		
		# Perform the hammering action using the string-based method
		player_ref.attempt_action("tower_repair")
	else:
		$message.visible = true
		var t = Timer.new()
		add_child(t)
		t.wait_time = 3
		t.one_shot = true
		t.connect("timeout", func(): $message.visible = false; t.queue_free())
		t.start()
		# You might want to add a UI notification here		player_ref.attempt_action("tower_repair")

# With this updated function:
func consume_materials_and_repair():
	# Check if we can remove all items first
	var can_remove_all = true
	
	# Create temporary items to check with remove_item
	var iron_item = Item.new()
	iron_item.id = "iron"

	var stone_item = Item.new()
	stone_item.id = "stone"
		
	var wood_item = Item.new()
	wood_item.id = "wood"

	var antenna_item = Item.new()
	antenna_item.id = "antenna"
	
	# Attempt to remove all items
	if player_ref.inventory.remove_item(iron_item, iron_required) and player_ref.inventory.remove_item(stone_item, stone_required) and player_ref.inventory.remove_item(wood_item, wood_required) and player_ref.inventory.remove_item(antenna_item, antenna_required):
		# If all removals are successful, repair the tower
		repair_tower()
	else:
		# This should rarely happen since we check beforehand, but good to have a fallback
		print("Failed to remove materials for tower repair")
		
func repair_tower():
	# Change sprite
	broken_sprite.visible = false
	repaired_sprite.visible = true
	is_broken = false
	show_win_screen()
	# Optional: Play a repair sound
	# $RepairSound.play()

func _on_interaction_area_body_entered(body):
	if body is Character:  # Using the class_name from your Character script
		player_ref = body

func _on_interaction_area_body_exited(body):
	if body is Character and player_ref == body:
		player_ref = null
# New functions for the win screen
func create_win_screen():
	# Create a CanvasLayer to show UI on top of everything
	win_screen = CanvasLayer.new()
	win_screen.layer = 10  # High layer number to be on top
	
	# Create a Control node for the UI
	var control = Control.new()
	control.anchor_right = 1.0
	control.anchor_bottom = 1.0
	control.name = "WinControl" # Give it a name for easier reference
	
	# Create a ColorRect for background
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.7)  # Semi-transparent black
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	
	# Create Label for "YOU WIN"
	var label = Label.new()
	label.text = "YOU WIN"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	
	# Set font size and make it bold
	var font_size = 48
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_color", Color(1, 1, 1))  # White text
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))  # Black outline
	
	# Add everything to the scene
	control.add_child(background)
	control.add_child(label)
	win_screen.add_child(control)
	
	# Hide it initially
	control.visible = false
	
	# Add to scene tree
	add_child(win_screen)
	
	# Store a reference to the control for showing/hiding
	win_screen = control
	
func show_win_screen():
	if win_screen:
		win_screen.visible = true
