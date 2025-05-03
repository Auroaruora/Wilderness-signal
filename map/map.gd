class_name Map extends TileMap

signal generation_finished
signal seed_updated(new_seed: int)

enum BaseTerrain {
	GRASS,
	SAND,
	WATER,
	DEEP_WATER,
	FOREST,
	CAVE
}

@onready var light_map: LightMap = $LightMap

@export var biome_regions: Array[BiomeRegion]
@export var noise: FastNoiseLite
@export var cave_noise: FastNoiseLite

var max_north_south_bias: float = .7
var entrance_spawned = false

func _ready():
	update_seed()

func generate_map(width: int, height: int, x_offset: int = 0, y_offset: int = 0):
	light_map.reset()
	var north_south_bias_step = max_north_south_bias / (height / 2.0)
	
	var grass_biome      = _find_biome(BaseTerrain.GRASS)
	var water_biome      = _find_biome(BaseTerrain.WATER)
	var deep_water_biome = _find_biome(BaseTerrain.DEEP_WATER)
	var half = height * 0.5
	var step = max_north_south_bias / half
	
	for y in range(height):
		var current_bias = clampf((half - y + y_offset) * step, -1, 1)
		for x in range(width):
			var cell = Vector2i(x + x_offset, y + y_offset)
		
			if x == 0 or y == 0 or x == width - 1 or y == height - 1:
				_place_biome(cell, deep_water_biome)
				continue
			var noise_value = noise.get_noise_2d(cell.x, cell.y) + current_bias
			light_map.add_position(cell)
			var chosen_biome: Biome = null
			for region in biome_regions:
				if noise_value > region.noise_value_cutoff:
					chosen_biome = region.biome
					break
			if not chosen_biome:
				chosen_biome = grass_biome
			_place_biome(cell, chosen_biome)
	light_map.recalculate_outdoor_lightmap()
	light_map.render_lightmap()
	generation_finished.emit()
	spawn_cave_entrance()


func _find_biome(id: int) -> Biome:
	for r in biome_regions:
		if r.biome.terrain_id == id:
			return r.biome
	push_error("can not find terrain_id=%d Biome" % id)
	return null

func _place_biome(cell: Vector2i, biome: Biome) -> void:
	set_cells_terrain_connect(0, [cell], 0, biome.terrain_id, false)
	if not biome.indoors:
		light_map.set_outdoors(cell, true)
	if biome.is_cave:
		generate_cave_scene(cell, biome.map_scenes, biome.cave_wall_scenes)
	else:
		generate_scene(cell, biome.map_scenes)

func generate_scene(cell: Vector2i, map_scenes: Array[MapScene]):
	var total_weight = get_total_weight(map_scenes)
	var cell_position = map_to_local(cell)
	generate_scene_at_position(map_scenes, total_weight, cell_position)

func generate_cave_scene(cell: Vector2i, map_scenes: Array[MapScene], wall_scenes: Array[MapScene]):
	var total_weight = get_total_weight(map_scenes)
	var total_wall_weight = get_total_weight(wall_scenes)
	
	var local_cell_position = map_to_local(cell)
	
	if cave_noise.get_noise_2d(local_cell_position.x, local_cell_position.y) > 0.22:
		generate_scene_at_position(map_scenes, total_weight, local_cell_position)
	else:
		generate_scene_at_position(wall_scenes, total_wall_weight, local_cell_position)

func get_total_weight(scene_list: Array[MapScene]) -> int:
	var total_weight = 0
	for scene in scene_list:
		total_weight += scene.weight
	
	return total_weight

func generate_scene_at_position(possible_scenes: Array[MapScene], total_weight: int, cell_position: Vector2):
	var weight_roll = randi_range(0, total_weight)
	
	for possible_scene in possible_scenes:
		weight_roll -= possible_scene.weight
		
		if weight_roll <= 0:
			if possible_scene.scene:
				instantiate_scene_at_position(possible_scene.scene, cell_position)
			
			return

func instantiate_scene_at_position(scene: PackedScene, at_position: Vector2):
	var instance = scene.instantiate() as Entity
	instance.position = at_position
	add_child(instance)

func clear_map():
	clear()
	
	for child in get_children():
		if child is LightMap:
			continue
		
		child.queue_free()


func update_seed(new_seed: int = 0):
	if new_seed == 0:
		randomize()
		noise.seed = randi()
	else:
		seed(new_seed)
		noise.seed = new_seed
	
	cave_noise.seed = noise.seed + 1
	
	seed_updated.emit(noise.seed)


func _on_player_moved_tiles(previous_position: Vector2i, new_position: Vector2i, player_instance: Character):
	light_map.remove_light(previous_position)
	light_map.add_light(new_position, player_instance.get_luminosity())

#func get_terrain_id_at(cell: Vector2i) -> int:
	#for region in biome_regions:
		#var noise_value = noise.get_noise_2d(cell.x, cell.y)
		#if noise_value > region.noise_value_cutoff:
			#return region.biome.terrain_id
	#return BaseTerrain.GRASS
	
func find_spawn_cell() -> Vector2i:
	var valid_cells: Array[Vector2i] = []

	for cell in get_used_cells(0):
		var tile_data = get_cell_tile_data(0, cell)
		if tile_data and tile_data.terrain != null:
			var terrain_id = tile_data.terrain
			if terrain_id == BaseTerrain.GRASS or terrain_id == BaseTerrain.SAND:
				valid_cells.append(cell)

	if valid_cells.size() > 0:
		return valid_cells[randi() % valid_cells.size()]
	else:
		push_error("No valid spawn cell found!")
		return Vector2i.ZERO

func spawn_cave_entrance():
	if entrance_spawned:
		return
	entrance_spawned = true
	var cave_cells: Array[Vector2i] = []
	var used_positions: Dictionary = {}

	for child in get_children():
		if child is Entity:
			used_positions[local_to_map(child.position)] = true

	for x in get_used_cells(0):
		var tile_data = get_cell_tile_data(0, x)
		var terrain_id = -1
		if tile_data and tile_data.terrain != null:
			terrain_id = tile_data.terrain
		if terrain_id == BaseTerrain.CAVE and not used_positions.has(x):
			var local_pos = map_to_local(x)
			if cave_noise.get_noise_2d(local_pos.x, local_pos.y) > 0.22:
				cave_cells.append(x)

	if cave_cells.size() > 0:
		var selected_cell = cave_cells[randi() % cave_cells.size()]
		var entrance_pos = map_to_local(selected_cell)
		
		var entrance_scene = preload("res://interaction/entrance.tscn")
		var instance = entrance_scene.instantiate()
		instance.position = entrance_pos
		add_child(instance)
