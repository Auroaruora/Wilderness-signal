extends Node2D

@onready var map = $Map
@onready var player = $Character
@onready var player_camera: Camera2D = $Character/PlayerCamera
@onready var game_map = $GameMap  # Add reference to the GameMap
@export var seed: int = 0
@export var map_width: int = 100
@export var map_height: int = 100
@export var player_spawn_cell: Vector2i = Vector2i(0, 0)
var initialized = false

func _ready():
	# We don't want to play music automatically - it will be started by the intro scene
	if has_node("BackgroundMusic"):
		$BackgroundMusic.autoplay = false
	
	if map.noise == null:
		map.noise = FastNoiseLite.new()
	if map.cave_noise == null:
		map.cave_noise = FastNoiseLite.new()
	
	map.generation_finished.connect(_on_map_generated)
	if GlobalData.world_seed != 0:
		seed = GlobalData.world_seed 
		print("Load the stored seed from GlobalData: ", seed)
	map.update_seed(seed)
	if GlobalData.world_seed == 0:
		GlobalData.world_seed = map.noise.seed
		print("seed have been stored in GlobalData: ", GlobalData.world_seed)
	map.generate_map(map_width, map_height)
	if GlobalData.return_position != Vector2.ZERO:
		player.global_position = GlobalData.return_position
		GlobalData.return_position = Vector2.ZERO

func _on_map_generated() -> void:  # Fixed function name
	player_spawn_cell = map.find_spawn_cell()
	
	var local_pos: Vector2 = map.map_to_local(player_spawn_cell)
	var world_pos: Vector2 = map.to_global(local_pos)
	print("seed：", map.noise.seed)
	player.global_position = world_pos
	player.map = map
	player.moved_tiles.connect(map._on_player_moved_tiles)
	if not GlobalData.entrance_used:
		spawn_butterfly(world_pos)
		# Load saved entity positions if returning through a portal
	var scene_path = scene_file_path  # Get current scene path
	var saved_entities = GlobalData.get_entity_positions(scene_path)
	# NEW CODE: Set position of existing Tower and Pickable Item
	# Position Tower
	if has_node("Tower"):
		if saved_entities.has("Tower") and GlobalData.entrance_used:
			# Use saved position
			$Tower.global_position = saved_entities["Tower"]
		else:
			# First time setup - use default position
			$Tower.global_position = world_pos + Vector2(-30, -30)
			
	if has_node("PickableAxe") and not GlobalData.entrance_used:
		$PickableAxe.global_position = world_pos
		# Optional: Add a small offset to prevent overlap
		$PickableAxe.global_position += Vector2(30, 30)
		
	if has_node("PickablePickaxe") and not GlobalData.entrance_used:
		$PickablePickaxe.global_position = world_pos
		# Optional: Add a small offset to prevent overlap
		$PickablePickaxe.global_position += Vector2(-30, 30)
	
	# Initialize the game map
	if has_node("GameMap"):
		# Pass the tower as a third parameter if it exists
		if has_node("Tower"):
			$GameMap.initialize(map, player, $Tower)
		else:
			$GameMap.initialize(map, player)
		
		# Load saved map state if returning through a portal
		if GlobalData.entrance_used:
			GlobalData.load_map_state($GameMap)
	
	initialized = true

func spawn_butterfly(spawn_pos: Vector2) -> void:
	# Load and instantiate the butterfly
	var butterfly_scene = preload("res://interaction/butterfly.tscn")  # Update path
	var butterfly = butterfly_scene.instantiate()
	add_child(butterfly)
	
	# Position it near the player
	butterfly.global_position = spawn_pos + Vector2(40, -40)
