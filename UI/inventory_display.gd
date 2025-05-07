class_name InventoryDisplay
extends Control

# Reference to the inventory - will be set in _ready() or by the parent
var inventory: Inventory
@export var normal_slot_sprite: Texture2D  # Sprite for normal unselected slot
@export var selected_slot_sprite: Texture2D  # Sprite for selected slot
@export var slot_color: Color = Color(0.3, 0.3, 0.3, 1.0)  # Keep for fallback
@export var selected_slot_color: Color = Color(0.5, 0.5, 0.5, 1.0)  # Keep for fallback
@export var font_color: Color = Color(1, 1, 1, 1)


@onready var slot_container = $BackgroundPanel/SlotContainer
@onready var tooltip_panel = $TooltipPanel

var slots = []
var selected_slot = -1

func _ready():
	
	# Try to automatically get reference to the inventory
	var character = get_parent().get_parent()
	
	if has_node("Inventory"):
		inventory = get_node("Inventory")
		
		# Connect signals from the inventory
		inventory.item_added.connect(_on_item_added)
		inventory.item_removed.connect(_on_item_removed)
		inventory.item_modified.connect(_on_item_modified)
		
	else:
		if character:
			print("Available nodes under character: " + str(character.get_children()))
	
	# Get all slot nodes
	collect_slots()
	## Initialize the tooltip
	#tooltip.visible = false
	# Initial display update
	update_inventory_display()
	# Select the first slot by default
	if slots.size() > 0:
		select_slot(0)

# Helper function to get or create the background sprite node
func ensure_background_sprite(slot):
	if slot.has_node("BackgroundSprite"):
		return slot.get_node("BackgroundSprite")
	else:
		# Create a new sprite node for the background
		var sprite = Sprite2D.new()
		sprite.name = "BackgroundSprite"
		sprite.centered = false  # Position at top-left
		sprite.position = Vector2.ZERO
		
		# Add it as the first child so it's behind everything else
		slot.add_child(sprite)
		slot.move_child(sprite, 0)
		
		return sprite

# Add this handler
func _on_item_modified(item):
	update_inventory_display()

func collect_slots():
	slots.clear()
	for child in slot_container.get_children():
		if child is Panel:
			slots.append(child)
			
			# Set up the slot
			var index = slots.size() - 1
			child.set_meta("index", index)
			
			# Connect signals
			child.gui_input.connect(_on_slot_gui_input.bind(index))
			child.mouse_entered.connect(_on_slot_mouse_entered.bind(index))
			child.mouse_exited.connect(_on_slot_mouse_exited.bind(index))

# In the InventoryDisplay script

func update_inventory_display():
	if not inventory:
		print("No inventory connected to display")
		return
	
	# Clear all slots first
	for slot in slots:
		var texture_rect = slot.get_node("ItemTexture")
		texture_rect.texture = null
		
		var stack_label = slot.get_node("StackLabel")
		stack_label.visible = false
	
	# Fill slots with inventory items
	for i in range(inventory.items.size()):
		if i >= slots.size():
			break
		
		var item = inventory.items[i]
		var slot = slots[i]
		
		# Comprehensive debugging
		print("Item Debug Info:")
		print("Item ID: ", item.id)
		print("Item Resource Path: ", item.resource_path)
		
		# Set item texture
		var texture_rect = slot.get_node("ItemTexture")
		
		# Multiple texture retrieval attempts
		if item.texture is Texture2D:
			texture_rect.texture = item.texture
			print("Texture set directly from item.texture")
		elif item.has_method("get_texture_path"):
			var loaded_texture = load(item.get_texture_path())
			if loaded_texture is Texture2D:
				texture_rect.texture = loaded_texture
				print("Texture loaded from path")
		elif "texture_path" in item and item.texture_path:
			var loaded_texture = load(item.texture_path)
			if loaded_texture is Texture2D:
				texture_rect.texture = loaded_texture
				print("Texture loaded from texture_path")
		else:
			print("WARNING: No texture found for ", item.id)
		
		# Set stack count if applicable
		var stack_label = slot.get_node("StackLabel")
		if item.stackable and item.stack_count > 1:
			stack_label.text = str(item.stack_count)
			stack_label.visible = true
		else:
			stack_label.visible = false

func select_slot(index: int):
	# Deselect previous slot
	if selected_slot != -1 and selected_slot < slots.size():
		var prev_slot = slots[selected_slot]
		# Reset background sprite
		var prev_bg_sprite = prev_slot.get_node("SlotBackground")
		prev_bg_sprite.modulate = Color(1, 1, 1, 1)
		
		# Reset item sprite if it exists
		var prev_item_sprite = prev_slot.get_node("ItemTexture")
		if prev_item_sprite:
			prev_item_sprite.modulate = Color(1, 1, 1, 1)
	# Select new slot
	selected_slot = index
	
	if index != -1 and index < slots.size():
		var slot = slots[index]
		
		# Light up background sprite
		var bg_sprite = slot.get_node("SlotBackground")
		bg_sprite.modulate = Color(1.3, 1.3, 1.3, 1)  # Brighter tint
		
		# Light up item sprite if it exists and has a texture
		var item_sprite = slot.get_node("ItemTexture")
		if item_sprite and item_sprite.texture:
			item_sprite.modulate = Color(1.3, 1.3, 1.3, 1)  # Match brightness with background
	
		# Update the inventory's selected item (whether the slot has an item or not)
		if inventory:
			inventory.select_item(index)
			
		# Show tooltip if item exists in inventory
		if inventory and index < inventory.items.size():
			show_tooltip(inventory.items[index])
		else:
			hide_tooltip()
	else:
		hide_tooltip()

func show_tooltip(item: Item):
	if item and tooltip_panel:
		# First let tooltip panel update its content
		tooltip_panel.display_item(item)
		
		# Get current slot
		var slot = slots[selected_slot]
		
		# Position tooltip above the current slot
		tooltip_panel.global_position = Vector2(
			slot.global_position.x + (slot.size.x / 2) - (tooltip_panel.size.x / 2),  # center over slot
			slot.global_position.y - tooltip_panel.size.y - 5  # 5 pixels above slot
		)

func hide_tooltip():
	tooltip_panel.clear()

#func _process(delta):
	## Update tooltip position to follow mouse
	#if tooltip.visible:
		#tooltip.global_position = get_viewport().get_mouse_position() + Vector2(10, 10)

func _on_item_added(item):
	update_inventory_display()

func _on_item_removed(item):
	update_inventory_display()

func _on_slot_gui_input(event, index):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				select_slot(index)
			elif event.double_click and inventory:
				# Handle item use here if needed
				if index < inventory.items.size():
					print("Using item: ", inventory.items[index].id)
	# Check for right mouse button press
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		# Get the currently selected item from the inventory
		var selected_item = inventory.get_selected_item()
		
		# Check if an item is selected and if it's a food item
		if selected_item and selected_item.is_food():
			# Use the food item
			print("Using food item: ", selected_item.id)
			## Remove the item from inventory
			inventory.remove_item(selected_item)
			var character = get_parent().get_parent()
			selected_item.use(character)

func _on_slot_mouse_entered(index):
	# Only show tooltip if this is the selected slot
	if inventory and index < inventory.items.size() and index == selected_slot:
		show_tooltip(inventory.items[index])

func _on_slot_mouse_exited(index):
	hide_tooltip()
