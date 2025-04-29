extends Node2D
@onready var map = $Map
@onready var player = $Character
@onready var player_camera: Camera2D = $Character/PlayerCamera

@export var seed: int = 0
@export var map_width: int = 100
@export var map_height: int = 100
@export var player_scene: PackedScene


func _ready():
	if map.noise == null:
		map.noise = FastNoiseLite.new()
	if map.cave_noise == null:
		map.cave_noise = FastNoiseLite.new()
	map.generation_finished.connect(_on_map_generated)
	
	map.update_seed(seed)
	map.generate_map(map_width, map_height)

func _on_map_generated() -> void:
	var player_spawn_cell := Vector2i(0, 0)
	var search_radius = 20
	var center_x = map_width / 2
	var center_y = map_height / 2
	var spawn_found = false
	
	for r in range(0, search_radius):
		for x in range(center_x - r, center_x + r + 1):
			for y in range(center_y - r, center_y + r + 1):
				var cell = Vector2i(x, y)
				var terrain_id = map.get_terrain_id_at(cell)
				if terrain_id == Map.BaseTerrain.GRASS or terrain_id == Map.BaseTerrain.SAND:
					player_spawn_cell = cell
					spawn_found = true
					break
			if spawn_found:
				break
		if spawn_found:
			break
			
	var local_pos: Vector2 = map.map_to_local(player_spawn_cell)
	var world_pos: Vector2 = map.to_global(local_pos)
	print("seed：", map.noise.seed)
	player.global_position = world_pos
	player.map = map
	player.moved_tiles.connect(map._on_player_moved_tiles)
	# NEW CODE: Set position of existing Tower and Pickable Item
	if has_node("Tower"):
		$Tower.global_position = world_pos
		# Optional: Add a small offset to prevent overlap
		$Tower.global_position += Vector2(-30, -30)
	
	if has_node("PickableItem"):
		$PickableItem.global_position = world_pos
		# Optional: Add a small offset to prevent overlap
		$PickableItem.global_position += Vector2(30, 30)

func _on_tunnel_used():
	player.save_state_to_global()
	var health = player.get_node_or_null("HealthSystem").current_health
	var hunger = player.get_node_or_null("HungerSystem").current_hunger
	Global.save_player_state(health, hunger, player.inventory.items)
	call_deferred("_deferred_load_dungeon")

func _deferred_load_dungeon():
	var dungeon = load("res://scenes/dungeon.tscn").instantiate()
	get_tree().root.add_child(dungeon)
	get_tree().root.remove_child.call_deferred(self)

func _on_dungeon_exited():
	var state = Global.load_player_state()
	player.get_node_or_null("HealthSystem").current_health = state["health"]
	player.get_node_or_null("HungerSystem").current_hunger = state["hunger"]
	
	player.inventory.items.clear()
	
	for item in state["inventory"]:
		if item is Resource:
			var copied_item = item.duplicate(true)
			player.inventory.items.append(copied_item)
	

	if player.inventory_display:
		player.inventory_display.update_inventory_display()
	
	get_tree().root.add_child(self)
