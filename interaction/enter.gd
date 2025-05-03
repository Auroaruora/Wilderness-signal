extends Area2D

const DUNGEON_SCENE_PATH := "res://boss_room/boss_room.tscn"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name == "Character":
		GlobalData.save_player_state(body)
		call_deferred("_change_scene")

func _change_scene() -> void:
	get_tree().change_scene_to_file(DUNGEON_SCENE_PATH)
