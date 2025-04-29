extends Node

var enemy_count: int = 0
var last_death_position: Vector2 = Vector2.ZERO

func _ready():
	get_tree().connect("node_added", Callable(self, "_on_node_added"))
	get_tree().connect("node_removed", Callable(self, "_on_node_removed"))
	enemy_count = get_tree().get_nodes_in_group("enemy").size()
	print("Initial enemy count: ", enemy_count)

func _on_node_added(node):
	if node.is_in_group("enemy"):
		enemy_count = get_tree().get_nodes_in_group("enemy").size()
		print("Enemy added, count: ", enemy_count)

func enemy_died(death_position: Vector2):
	enemy_count -= 1
	print("Enemy count: ", enemy_count)
	last_death_position = death_position
	if enemy_count <= 0:
		spawn_portal()

func spawn_portal():
	var portal_scene = preload("res://scenes/portal.tscn")
	var portal = portal_scene.instantiate()
	portal.position = last_death_position
	get_tree().current_scene.call_deferred("add_child", portal)
