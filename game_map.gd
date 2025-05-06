class_name GameMap extends CanvasLayer

# Reference to the main map
var map: Map
# Reference to the player
var player: Character

# Texture for the map
var map_texture: ImageTexture
var map_image: Image

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

func _ready():
	# Hide the map initially
	visible = false
	
	# Set up input processing
	set_process_input(true)

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_M:
		# Toggle map visibility
		visible = !visible
		
		# Only process when visible
		set_process(visible)
		
		# Update map and player marker if becoming visible
		if visible and map and player:
			generate_map_texture()
			update_player_marker()

func initialize(game_map: Map, game_player: Character):
	map = game_map
	player = game_player
	
	# Create the texture with proper dimensions
	create_initial_texture()
	
	# Generate the initial map texture
	generate_map_texture()

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
	
	# Set the MapContent size to match the texture size
	map_content.custom_minimum_size = Vector2(image_width, image_height)
	map_content.size = Vector2(image_width, image_height)
	
	# Store the map bounds for player marker positioning
	self.min_map_cell = Vector2i(min_x, min_y)
	self.max_map_cell = Vector2i(max_x, max_y)
	self.map_scale = scale
func _process(_delta):
	if visible and map and player:
		update_player_marker()

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
	
	# Print performance information
	var elapsed = Time.get_ticks_msec() - start_time
	print("Map generation took: ", elapsed, " ms")

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
	# Since PlayerMarker is a direct child of MapContent, we don't need to account for MapContent's position
	player_marker.position = Vector2(
		pixel_x - (player_marker.size.x / 2),
		pixel_y - (player_marker.size.y / 2)
	)
	
	# Print debug info to help with troubleshooting
	print("Player world cell: ", player_cell)
	print("Player map position: ", player_marker.position)
# Call this when the map changes (regenerates)
func refresh_map():
	if visible:
		generate_map_texture()
