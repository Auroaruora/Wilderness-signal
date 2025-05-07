extends Area2D

func _ready() -> void:
	self.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name == "Character":
		GlobalData.save_player_state(body)
		call_deferred("_change_scene")

func _change_scene() -> void:
	var return_scene = GlobalData.previous_scene
	get_tree().change_scene_to_file(return_scene)
