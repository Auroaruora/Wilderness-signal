extends CanvasLayer
var world_scene = preload("res://world.tscn")
var current_step = 0

func _ready():
	# Start the intro sequence
	show_first_message()

func show_first_message():
	$BlackBackground.visible = true
	$Message.text = "My head... it hurts."
	$Message.modulate.a = 0  # Start fully transparent
	
	# Fade in text
	var tween = create_tween()
	tween.tween_property($Message, "modulate:a", 1.0, 2.0)  # Fade in over 2 seconds
	tween.tween_interval(2.0)  # Wait 2 seconds
	tween.tween_property($Message, "modulate:a", 0.0, 2.0)  # Fade out over 2 seconds
	tween.tween_callback(show_second_message)

func show_second_message():
	$Message.text = "Where... am I?"
	
	# Fade in second text
	var tween = create_tween()
	tween.tween_property($Message, "modulate:a", 1.0, 2.0)  # Fade in over 2 seconds
	tween.tween_interval(2.0)  # Wait 2 seconds
	tween.tween_property($Message, "modulate:a", 0.0, 2.0)  # Fade out over 2 seconds
	tween.tween_callback(transition_to_game)

func transition_to_game():
	# Change to the main game scene
	get_tree().change_scene_to_packed(world_scene)
