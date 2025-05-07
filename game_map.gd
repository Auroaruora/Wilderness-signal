class_name GameMap extends CanvasLayer

# Reference to the main map
var map: Map
# Reference to the player
var player: Character

# Texture for the map
var map_texture: ImageTexture
var map_image: Image

# Fog of war variables
var fog_texture: ImageTexture
var fog_image: Image
var explored_areas = {}  # Dictionary to track explored areas
var visibility_radius: int = 5  # Radius (in tiles) around player that's visible
var first_generation: bool = true
var needs_fog_update: bool = false

var tower: Node2D

# Dictionary to store terrain colors
var terrain_colors = {
	Map.BaseTerrain.GRASS: Color("#8BB246"),      # Light green
	Map.BaseTerrain.SAND: Color("#E2C673"),       # Tan
	Map.BaseTerrain.WATER: Color("#3F75B8"),      # Blue
	Map.BaseTerrain.DEEP_WATER: Color("#235C95"), # Dark blue
	Map.BaseTerrain.FOREST: Color("#3B6D1B"),     # Dark green
	Map.BaseTerrain.CAVE: Color("#4A3933")        # Brown
}

# Updated node paths to account for the MapContainer
@onready var map_content: TextureRect = $MapContainer/MapContent
@onready var player_marker: TextureRect = $MapContainer/MapContent/PlayerMarker
@onready var tower_marker: TextureRect = $MapContainer/MapContent/TowerMarker

func _ready():
	# Hide the map initially
	visible = false
	
	# Set up input processing
	set_process_input(true)
	
	# CHANGED: Always process, even when the map is not visible
	set_process(true)

func _input(event):
	if Input.is_action_just_pressed("toggle_map"):
		# Toggle map visibility
		visible = !visible
		
		# CHANGED: If becoming visible, update the map display
		if visible and map and player:
			generate_map_texture()
			update_player_marker()
			
			# Make tower marker visible when map is toggled on
			if tower and tower_marker:
				tower_marker.visible = true
			
			# Apply the fog update if needed
			if needs_fog_update:
				apply_fog_to_map()
				needs_fog_update = false

func initialize(game_map: Map, game_player: Character, game_tower: Node2D = null):
	map = game_map
	player = game_player
	tower = game_tower
	# Create the texture with proper dimensions
	create_initial_texture()
	
	# Generate the initial map texture
	generate_map_texture()
	
	# Update explored areas based on player's initial position
	update_explored_areas()

func create_initial_texture():
	# Get the actual map dimensions from the tilemap
	var used_cells = map.get_used_cells(0)
	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF
	
	for cell in used_cells:
		min_x = min(min_x, cell.x)
		min_y = min(min_y, cell.y)
		max_x = max(max_x, cell.x)
		max_y = max(max_y, cell.y)
	
	# Calculate map dimensions
	var map_width = max_x - min_x + 1
	var map_height = max_y - min_y + 1
	
	# Set reasonable constraints for the map texture size
	var viewport_size = get_viewport().get_visible_rect().size
	var max_map_size = Vector2i(int(viewport_size.x * 0.9), int(viewport_size.y * 0.9))
	
	# Calculate a proper scale that preserves aspect ratio
	var scale_x = float(max_map_size.x) / map_width
	var scale_y = float(max_map_size.y) / map_height
	var scale = min(scale_x, scale_y)
	
	# Calculate the final image size, preserving map aspect ratio
	var image_width = int(map_width * scale)
	var image_height = int(map_height * scale)
	
	# Create the image with proper dimensions
	map_image = Image.create(image_width, image_height, false, Image.FORMAT_RGBA8)
	map_texture = ImageTexture.create_from_image(map_image)
	map_content.texture = map_texture
	
	# Create the fog of war image
	fog_image = Image.create(image_width, image_height, false, Image.FORMAT_RGBA8)
	fog_image.fill(Color(0, 0, 0, 1))  # Start with completely black (unexplored)
	fog_texture = ImageTexture.create_from_image(fog_image)
	
	# Set the MapContent size to match the texture size
	map_content.custom_minimum_size = Vector2(image_width, image_height)
	map_content.size = Vector2(image_width, image_height)
	
	# Store the map bounds for player marker positioning
	self.min_map_cell = Vector2i(min_x, min_y)
	self.max_map_cell = Vector2i(max_x, max_y)
	self.map_scale = scale

func update_tower_marker():
	if not tower or not tower_marker or not map:
		return
	
	# Get tower's current cell position in the game world
	var tower_cell = map.local_to_map(map.to_local(tower.global_position))
	
	# Calculate relative position within the map (0.0 to 1.0)
	var map_width = max_map_cell.x - min_map_cell.x
	var map_height = max_map_cell.y - min_map_cell.y
	
	# Avoid division by zero
	if map_width <= 0 or map_height <= 0:
		return
	
	var rel_x = clampf(float(tower_cell.x - min_map_cell.x) / map_width, 0.0, 1.0)
	var rel_y = clampf(float(tower_cell.y - min_map_cell.y) / map_height, 0.0, 1.0)
	
	# Convert to pixel coordinates within the map texture
	var pixel_x = rel_x * map_content.size.x
	var pixel_y = rel_y * map_content.size.y
	
	# Center the marker on the tower's position
	tower_marker.position = Vector2(
		pixel_x - (tower_marker.size.x / 2),
		pixel_y - (tower_marker.size.y / 2)
	)
	
	# Ensure tower marker is visible
	tower_marker.visible = true

func _process(_delta):
	# CHANGED: Always update explored areas, even when map is not visible
	if map and player:
		if visible:
			update_player_marker()
			if tower:
				update_tower_marker()
		
		# Always update explored areas
		update_explored_areas()

# Function to update explored areas based on player position
func update_explored_areas():
	# Get player's current cell position
	var player_cell = map.local_to_map(map.to_local(player.global_position))
	
	# Check if any new areas are explored
	var new_areas_explored = false
	
	# Mark the visibility area around the player
	for y in range(-visibility_radius, visibility_radius + 1):
		for x in range(-visibility_radius, visibility_radius + 1):
			var cell = Vector2i(player_cell.x + x, player_cell.y + y)
			
			# Check if the cell is within the map bounds
			if cell.x >= min_map_cell.x and cell.x <= max_map_cell.x and cell.y >= min_map_cell.y and cell.y <= max_map_cell.y:
				# Calculate the distance from the player (using squared distance for efficiency)
				var distance_squared = x*x + y*y
				
				# Only mark tiles within the visibility radius
				if distance_squared <= visibility_radius * visibility_radius:
					# Mark this cell as explored in our dictionary
					var key = str(cell.x) + "," + str(cell.y)
					if not explored_areas.has(key):
						explored_areas[key] = true
						new_areas_explored = true
	
	# Update the fog of war texture only if new areas were explored
	if new_areas_explored:
		update_fog_texture()

# Function to update the fog texture based on explored areas
func update_fog_texture():
	# Clear the fog to black (unexplored)
	fog_image.fill(Color(0, 0, 0, 1))
	
	# For each explored area, clear the fog
	for key in explored_areas.keys():
		var coords = key.split(",")
		var cell_x = int(coords[0])
		var cell_y = int(coords[1])
		
		# Calculate the position and size of this cell in the texture
		var x = int((cell_x - min_map_cell.x) * map_scale)
		var y = int((cell_y - min_map_cell.y) * map_scale)
		var width = ceil(map_scale) + 1  # Add 1 to eliminate gaps
		var height = ceil(map_scale) + 1
		
		# Use the draw_rect method to clear this area of the fog
		fog_image.fill_rect(Rect2i(x, y, width, height), Color(0, 0, 0, 0))
	
	# Update the fog texture
	fog_texture.update(fog_image)
	
	# CHANGED: Only apply fog to map if visible, otherwise flag for update
	if visible:
		apply_fog_to_map()
	else:
		needs_fog_update = true

# Function to apply the fog to the map
func apply_fog_to_map():
	# Create a copy of the map image to work with
	var combined_image = map_image.duplicate()
	
	# Blit the fog onto the map image with alpha blending
	combined_image.blend_rect(fog_image, Rect2i(0, 0, fog_image.get_width(), fog_image.get_height()), 
		Vector2i(0, 0))
	
	# Update the map texture with the combined image
	map_texture.update(combined_image)

func generate_map_texture():
	if not map:
		return
	
	# Start measuring time
	var start_time = Time.get_ticks_msec()
	
	# Get the used cells from the map
	var used_cells = map.get_used_cells(0)
	
	# Clear the image
	map_image.fill(Color(0, 0, 0, 0))
	
	# Use a more efficient drawing approach - draw rectangles instead of individual pixels
	for cell in used_cells:
		var tile_data = map.get_cell_tile_data(0, cell)
		if tile_data and tile_data.terrain != null:
			var terrain_id = tile_data.terrain
			var color = terrain_colors.get(terrain_id, Color.GRAY)
			
			# Calculate the position and size of this cell
			var x = int((cell.x - min_map_cell.x) * map_scale)
			var y = int((cell.y - min_map_cell.y) * map_scale)
			var width = ceil(map_scale) + 1  # Add 1 to eliminate gaps
			var height = ceil(map_scale) + 1
			
			# Use the draw_rect method instead of pixel-by-pixel
			map_image.fill_rect(Rect2i(x, y, width, height), color)
	
	# Update the texture
	map_texture.update(map_image)
	
	# If this is the first time generating the map, update explored areas
	if first_generation:
		update_explored_areas()
		first_generation = false
	else:
		# Apply the existing fog
		apply_fog_to_map()
	
	# Print performance information
	var elapsed = Time.get_ticks_msec() - start_time
	#print("Map generation took: ", elapsed, " ms")

# Store map bounds for player positioning
var min_map_cell: Vector2i
var max_map_cell: Vector2i
var map_scale: float = 1.0

func update_player_marker():
	# Get player's current cell position in the game world
	var player_cell = map.local_to_map(map.to_local(player.global_position))
	
	# Calculate the player's position as a percentage of the total map size
	var map_width = max_map_cell.x - min_map_cell.x
	var map_height = max_map_cell.y - min_map_cell.y
	
	# Avoid division by zero
	if map_width <= 0 or map_height <= 0:
		return
	
	# Calculate relative position within the map (0.0 to 1.0)
	var rel_x = clampf(float(player_cell.x - min_map_cell.x) / map_width, 0.0, 1.0)
	var rel_y = clampf(float(player_cell.y - min_map_cell.y) / map_height, 0.0, 1.0)
	
	# Convert to pixel coordinates within the map texture
	var pixel_x = rel_x * map_content.size.x
	var pixel_y = rel_y * map_content.size.y
	
	# Center the marker on the player's position
	player_marker.position = Vector2(
		pixel_x - (player_marker.size.x / 2),
		pixel_y - (player_marker.size.y / 2)
	)

# Call this when the map changes (regenerates)
func refresh_map():
	if visible:
		generate_map_texture()
