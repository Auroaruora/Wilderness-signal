extends Node

var player: Node = null

func change_scene_with_player(scene_path: String, spawn_position: Vector2):
	var new_scene = load(scene_path).instantiate()
	
	if get_tree().current_scene:
		get_tree().current_scene.queue_free()
	
	get_tree().root.add_child(new_scene)
	get_tree().current_scene = new_scene
	
	if player:
		new_scene.add_child(player)
		player.global_position = spawn_position
	else:
		push_error("[GameManager] No player assigned!")
	print("Switching to scene:", scene_path)
	print("Player position set to:", spawn_position)

func register_player(p: Node):
	player = p
