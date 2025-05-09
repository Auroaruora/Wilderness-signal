# enter.gd
extends Area2D

const DUNGEON_SCENE_PATH := "res://boss_room/boss_room.tscn"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name == "Character":
		# Save all entity positions
# Find the main scene
		var main_scene = get_parent()
		while main_scene != null and not main_scene.has_node("Tower") and not main_scene.has_node("GameMap"):
			main_scene = main_scene.get_parent()
		
		if main_scene == null:
			print("ERROR: Could not find main scene")
			return
		var scene_path = "res://world.tscn"
		var entities = {}
		
		# Save any important entities' positions
		if main_scene.has_node("Tower"):
			entities["Tower"] = main_scene.get_node("Tower").global_position
		
		# Save any other entities you need to track
		GlobalData.save_entity_positions(scene_path, entities)
		GlobalData.save_player_state(body)
		var game_map = get_tree().current_scene.get_node("GameMap")
		if game_map:
			GlobalData.save_map_state(game_map)
		else:
			print("ERROR: GameMap not found")
		GlobalData.previous_scene = get_tree().current_scene.scene_file_path
		GlobalData.return_position = body.global_position
		GlobalData.entrance_used = true
		
		
		call_deferred("_change_scene")

func _change_scene() -> void:
	get_tree().change_scene_to_file(DUNGEON_SCENE_PATH)
