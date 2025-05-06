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
@onready var player_marker: TextureRect = $MapContainer/PlayerMarker

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
	
	# Create initial empty image and texture
	create_initial_texture()

func create_initial_texture():
	# Get screen size to determine map image size
	var viewport_size = get_viewport().get_visible_rect().size
	var map_size = Vector2i(int(viewport_size.x * 0.9), int(viewport_size.y * 0.9))
	
	# Create an empty image for the map with a fixed size
	map_image = Image.create(100, 100, false, Image.FORMAT_RGBA8)
	map_texture = ImageTexture.create_from_image(map_image)
	map_content.texture = map_texture

func _process(_delta):
	if visible and map and player:
		update_player_marker()

func generate_map_texture():
	if not map:
		return
	
	# Get the used cells from the map
	var used_cells = map.get_used_cells(0)
	
	# Calculate the bounds of the map
	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF
	
	for cell in used_cells:
		min_x = min(min_x, cell.x)
		min_y = min(min_y, cell.y)
		max_x = max(max_x, cell.x)
		max_y = max(max_y, cell.y)
	
	# Get the current map image size
	var image_size = map_image.get_size()
	
	# Calculate the scale factor to fit the map into the texture
	var map_width = max_x - min_x + 1
	var map_height = max_y - min_y + 1
	var scale_x = float(image_size.x) / map_width
	var scale_y = float(image_size.y) / map_height
	var scale = min(scale_x, scale_y)
	
	# Clear the image
	map_image.fill(Color(0, 0, 0, 0))
	
	# Draw each cell as a pixel in the texture
	for cell in used_cells:
		var tile_data = map.get_cell_tile_data(0, cell)
		if tile_data and tile_data.terrain != null:
			var terrain_id = tile_data.terrain
			var color = terrain_colors.get(terrain_id, Color.GRAY)
			
			# Convert cell coordinates to image coordinates
			var x = int((cell.x - min_x) * scale)
			var y = int((cell.y - min_y) * scale)
			
			# Make sure the pixel is within the image bounds
			if x >= 0 and x < image_size.x and y >= 0 and y < image_size.y:
				# Draw a slightly larger pixel (2x2) for better visibility
				for dx in range(max(1, int(scale))):
					for dy in range(max(1, int(scale))):
						var px = x + dx
						var py = y + dy
						if px < image_size.x and py < image_size.y:
							map_image.set_pixel(px, py, color)
	
	# Update the texture (same size, so this should work)
	map_texture.update(map_image)
	
	# Store the map bounds for player marker positioning
	self.min_map_cell = Vector2i(min_x, min_y)
	self.max_map_cell = Vector2i(max_x, max_y)
	self.map_scale = scale

# Store map bounds for player positioning
var min_map_cell: Vector2i
var max_map_cell: Vector2i
var map_scale: float = 1.0

func update_player_marker():
	# Get player's current cell position
	var player_cell = map.local_to_map(map.to_local(player.global_position))
	
	# Calculate the player's position as a percentage of the total map size
	var map_width = max_map_cell.x - min_map_cell.x
	var map_height = max_map_cell.y - min_map_cell.y
	
	# Avoid division by zero
	if map_width <= 0 or map_height <= 0:
		return
	
	# Calculate player position as percentage of total map (0.0 to 1.0)
	var player_percent_x = clampf(float(player_cell.x - min_map_cell.x) / map_width, 0.0, 1.0)
	var player_percent_y = clampf(float(player_cell.y - min_map_cell.y) / map_height, 0.0, 1.0)
	
	# Get the MapContent's size
	var content_size = map_content.size
	
	# Position the player marker within the MapContent boundaries
	player_marker.position = Vector2(
		map_content.position.x + (player_percent_x * content_size.x) - (player_marker.size.x / 2),
		map_content.position.y + (player_percent_y * content_size.y) - (player_marker.size.y / 2)
	)
# Call this when the map changes (regenerates)
func refresh_map():
	if visible:
		generate_map_texture()
