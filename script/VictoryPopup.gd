extends CanvasLayer

func _ready():
	$Control/ReplayButton.pressed.connect(_on_replay_button_pressed)

func _on_replay_button_pressed():
	get_tree().change_scene_to_file("res://scenes/world.tscn")
	get_parent().queue_free()
	await get_tree().process_frame
