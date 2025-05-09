extends "res://resources/item_pickup.gd"

func on_item_picked_up():
	var boss = get_tree().current_scene.get_node("Boss")
	var camera = get_tree().current_scene.get_node("PlayerCamera")
	var quake = get_tree().current_scene.get_node("QuakeSFX")
	var bgm = get_tree().current_scene.get_node("bgm")
	if camera and camera.has_method("shake"):
		camera.shake(12.0,4)
		quake.play()
	boss.activate()
	bgm.play()
