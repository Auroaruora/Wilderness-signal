extends "res://resources/item_pickup.gd"

func on_item_picked_up():
	var boss = get_tree().current_scene.get_node("Boss")
	boss.activate()
