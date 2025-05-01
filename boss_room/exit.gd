extends Area2D

const EXIT_SCENE_PATH := "res://scenes/world.tscn"

func _ready() -> void:
	self.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name == "Character":
		call_deferred("_change_scene")

func _change_scene() -> void:
	get_tree().change_scene_to_file(EXIT_SCENE_PATH)
