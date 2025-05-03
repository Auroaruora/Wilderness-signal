extends Node2D
@onready var map = $Map
@onready var player = $Character
@onready var player_camera: Camera2D = $Character/PlayerCamera

@export var seed: int = 0
@export var map_width: int = 100
@export var map_height: int = 100
@export var player_spawn_cell: Vector2i = Vector2i(0, 0)

func _ready():
	if map.noise == null:
		map.noise = FastNoiseLite.new()
	if map.cave_noise == null:
		map.cave_noise = FastNoiseLite.new()
	map.generation_finished.connect(_on_map_generated)
	
	map.update_seed(seed)
	map.generate_map(map_width, map_height)

func _on_map_generated() -> void:
	player_spawn_cell = map.find_spawn_cell()
	
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
	
	if has_node("PickableAxe"):
		$PickableAxe.global_position = world_pos
		# Optional: Add a small offset to prevent overlap
		$PickableAxe.global_position += Vector2(30, 30)
		
	if has_node("PickablePickaxe"):
		$PickablePickaxe.global_position = world_pos
		# Optional: Add a small offset to prevent overlap
		$PickablePickaxe.global_position += Vector2(-30, 30)
