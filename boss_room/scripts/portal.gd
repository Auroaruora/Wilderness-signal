extends Area2D

func _ready():
	$AnimatedSprite2D.play("default")
	collision_layer = 1
	collision_mask = 1
	body_entered.connect(Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.name == "Character":
		GlobalData.save_player_state(body)
		call_deferred("_change_scene")

func _change_scene() -> void:
	await get_tree().process_frame
	print("GlobalData.previous_scene: ", GlobalData.previous_scene)
	var return_scene = GlobalData.previous_scene
	print("Switch scene to：", return_scene)
	if get_tree():
		get_tree().change_scene_to_file(return_scene)
	else:
		print("The current node has not joined the scene tree yet")
