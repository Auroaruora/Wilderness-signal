class_name RepairableTower extends StaticBody2D

# Two sprites for different tower states
@onready var broken_sprite = $BrokenSprite
@onready var repaired_sprite = $RepairedSprite
@onready var interaction_area = $InteractionArea
@onready var message = $message
@onready var signal_sprite = $Signal
@onready var audio_player = $AudioStreamPlayer2D

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
		t.timeout.connect(func(): $message.visible = false; t.queue_free())
		t.start()

func consume_materials_and_repair():
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

func _on_interaction_area_body_entered(body):
	if body is Character:  # Using the class_name from your Character script
		player_ref = body

func _on_interaction_area_body_exited(body):
	if body is Character and player_ref == body:
		player_ref = null

# Create the win screen
func create_win_screen():
	# Create a CanvasLayer to show UI on top of everything
	var canvas = CanvasLayer.new()
	canvas.layer = 10  # High layer number to be on top
	add_child(canvas)
	
	# Create a Control node for the UI
	var control = Control.new()
	control.anchor_right = 1.0
	control.anchor_bottom = 1.0
	control.name = "WinControl"
	canvas.add_child(control)
	
	# Create a ColorRect for background (starting transparent)
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.0)  # Start fully transparent
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.name = "Background"
	control.add_child(background)
	
	# Create RichTextLabel for the typing text
	var creepy_message = RichTextLabel.new()
	creepy_message.bbcode_enabled = false  # Disable BBCode initially
	creepy_message.text = ""  # Start empty, will be filled with typing effect
	creepy_message.fit_content = true
	creepy_message.scroll_active = false
	
	# Center the message on screen
	creepy_message.anchor_left = 0.5
	creepy_message.anchor_top = 0.5
	creepy_message.anchor_right = 0.5
	creepy_message.anchor_bottom = 0.5
	creepy_message.size = Vector2(700, 100)
	creepy_message.position = Vector2(-300, -100)  # Center it
	creepy_message.name = "CreepyMessage"
	
	# Set text alignment
	creepy_message.auto_translate = false
	#creepy_message.text_direction = TEXT_DIRECTION_AUTO
	
	# Bold the text and center it if possible
	var font_size = 32
	creepy_message.add_theme_font_size_override("normal_font_size", font_size)
	creepy_message.add_theme_font_size_override("bold_font_size", font_size)
	creepy_message.add_theme_constant_override("outline_size", 2)
	creepy_message.add_theme_color_override("default_color", Color(0, 0, 0))  # White text
	creepy_message.modulate.a = 0  # Start invisible
	control.add_child(creepy_message)
	
	var text_style_box = StyleBoxFlat.new()
	text_style_box.bg_color = Color(1, 1, 1, 0.3)  # Semi-transparent black
	text_style_box.corner_radius_top_left = 8
	text_style_box.corner_radius_top_right = 8
	text_style_box.corner_radius_bottom_left = 8
	text_style_box.corner_radius_bottom_right = 8
	creepy_message.add_theme_stylebox_override("normal", text_style_box)
	# Create "TBC" label
	var tbc_label = Label.new()
	tbc_label.text = "TBC"
	tbc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tbc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tbc_label.anchor_right = 1.0
	tbc_label.anchor_bottom = 1.0
	tbc_label.name = "TBCLabel"
	
	# Set font properties for TBC
	tbc_label.add_theme_font_size_override("font_size", 48)
	tbc_label.add_theme_constant_override("outline_size", 2)
	tbc_label.add_theme_color_override("font_color", Color(1, 1, 1))  # White text
	tbc_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))  # Black outline
	tbc_label.modulate.a = 0  # Start invisible
	control.add_child(tbc_label)
	
	# Hide it initially
	control.visible = false
	
	# Store a reference to the control for showing/hiding
	win_screen = control

# Show the win screen and start the sequence
func show_win_screen():
	if not win_screen:
		return
		
	# Handle the animated sprite (signal)
	if signal_sprite:
		signal_sprite.visible = true
		signal_sprite.play()
	
	# Play the audio
	if audio_player:
		audio_player.play()
	
	# Make the win screen visible
	win_screen.visible = true
	
	# Schedule the creepy message to appear after 2 seconds
	var timer = Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.wait_time = 2.0
	timer.timeout.connect(func(): 
		show_creepy_message()
		timer.queue_free()
	)
	timer.start()

# Show the creepy message with typing effect
func show_creepy_message():
	var creepy_message = win_screen.get_node("CreepyMessage")
	
	# Set the full text right away (with or without BBCode formatting)
	creepy_message.bbcode_enabled = true
	creepy_message.text = "[center][b]What sleeps in your past was never erased.[/b]\n[b]When the sun goes down, it must be faced.[/b][/center]"
	
	# Make sure the text is initially invisible by setting visible_ratio to 0
	creepy_message.visible_ratio = 0.0
	
	# Make the text container visible
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(creepy_message, "modulate:a", 1.0, 0.5)
	fade_in_tween.finished.connect(func(): start_typing_effect())


# Type the message character by character using visible_ratio
func start_typing_effect():
	var creepy_message = win_screen.get_node("CreepyMessage")
	
	# Create a tween to animate the visible_ratio from 0 to 1
	var typing_tween = create_tween()
	
	# Calculate timing based on text length and desired typing speed
	var text_length = creepy_message.text.length()
	var chars_per_second = 20 # Adjust for faster/slower typing
	var total_typing_duration = text_length / chars_per_second
	
	# Animate visible_ratio from 0 to 1 over the calculated duration
	typing_tween.tween_property(creepy_message, "visible_ratio", 1.0, total_typing_duration)
	
	# Continue with the sequence after typing is done
	typing_tween.finished.connect(func():
		# Wait after typing completes, then fade out
		var pause_timer = Timer.new()
		add_child(pause_timer)
		pause_timer.one_shot = true
		pause_timer.wait_time = 3.0
		pause_timer.timeout.connect(func():
			fade_message_and_show_tbc()
			pause_timer.queue_free()
		)
		pause_timer.start()
	)


# Fade out message and show TBC
func fade_message_and_show_tbc():
	var background = win_screen.get_node("Background")
	var creepy_message = win_screen.get_node("CreepyMessage")
	var tbc_label = win_screen.get_node("TBCLabel")
	
	# Fade out message
	var fade_tween = create_tween()
	fade_tween.tween_property(creepy_message, "modulate:a", 0.0, 1.5)
	
	# Wait for message to fade, then darken screen
	var screen_timer = Timer.new()
	add_child(screen_timer)
	screen_timer.one_shot = true
	screen_timer.wait_time = 1.5
	screen_timer.timeout.connect(func():
		# Darken the screen
		var black_tween = create_tween()
		black_tween.tween_property(background, "color", Color(0, 0, 0, 1.0), 2.0)
		
		# Show TBC after screen darkens
		var tbc_timer = Timer.new()
		add_child(tbc_timer)
		tbc_timer.one_shot = true
		tbc_timer.wait_time = 2.0
		tbc_timer.timeout.connect(func():
			# Make sure the label is visible with proper text
			tbc_label.text = "TBC"
			
			# Make it visible with a tween
			var tbc_tween = create_tween()
			tbc_tween.tween_property(tbc_label, "modulate:a", 1.0, 1.0)
			tbc_timer.queue_free()
		)
		tbc_timer.start()
		
		screen_timer.queue_free()
	)
	screen_timer.start()
