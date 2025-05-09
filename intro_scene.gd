extends CanvasLayer

var world_resource_path = "res://world.tscn"
var world_instance = null
var loader = null
var time_max = 100 # msec to use loading per frame
var loading_progress = 0

func _ready():
	# Start background loading immediately
	loader = ResourceLoader.load_threaded_request(world_resource_path)
	# Start the intro sequence
	show_first_message()

func _process(delta):
	# If we're not loading, don't do anything
	if loader == null:
		return
		
	# Check for loading status
	var status = ResourceLoader.load_threaded_get_status(world_resource_path)
	
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		# Still loading, update progress
		var progress_array = []
		ResourceLoader.load_threaded_get_status(world_resource_path, progress_array)
		if progress_array.size() > 0:
			loading_progress = progress_array[0] * 100
			print("Loading: ", loading_progress, "%")
	
	elif status == ResourceLoader.THREAD_LOAD_LOADED:
		# Loading completed!
		var resource = ResourceLoader.load_threaded_get(world_resource_path)
		world_instance = resource.instantiate()
		loader = null
		print("World scene loaded successfully!")
		
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		# Loading failed
		print("Error: Failed to load world scene!")
		loader = null
func activate_world():
	# Enable all processes on the world
	world_instance.set_process(true)
	world_instance.set_process_input(true)
	world_instance.set_physics_process(true)
	
	# Start the music now that the intro is done
	if world_instance.has_node("BackgroundMusic"):
		world_instance.get_node("BackgroundMusic").play()
	
	# IMPORTANT: Set the world as the current scene
	get_tree().current_scene = world_instance
	
	# Remove the intro scene
	queue_free()
	
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
	tween.tween_callback(check_world_loaded)

func check_world_loaded():
	# Check if world is loaded, otherwise wait
	if world_instance != null:
		transition_to_game()
	else:
		# World not ready yet, show loading message and check again in a moment
		$Message.text = "Loading world... " + str(int(loading_progress)) + "%"
		$Message.modulate.a = 1.0
		
		# Check again in 0.5 seconds
		var timer = get_tree().create_timer(0.5)
		timer.timeout.connect(check_world_loaded)

func transition_to_game():
	# Now we're sure the world is loaded
	
	# Disable music in the world scene until we want it to play
	if world_instance.has_node("BackgroundMusic"):
		world_instance.get_node("BackgroundMusic").autoplay = false
	
	# Set up the world before adding it to scene tree
	world_instance.set_process(false)
	world_instance.set_process_input(false)
	world_instance.set_physics_process(false)
	
	# Add the world to the scene tree but keep it hidden
	get_tree().root.add_child(world_instance)
	
	# Create a fade transition
	var tween = create_tween()
	tween.tween_property($BlackBackground, "modulate:a", 0.0, 1.0)
	tween.tween_callback(activate_world)
