class_name InventoryDisplay
extends Control

# Reference to the inventory - will be set in _ready() or by the parent
var inventory: Inventory
@export var slot_color: Color = Color(0.3, 0.3, 0.3, 1.0)
@export var selected_slot_color: Color = Color(0.5, 0.5, 0.5, 1.0)
@export var font_color: Color = Color(1, 1, 1, 1)

@onready var slot_container = $BackgroundPanel/SlotContainer
@onready var tooltip = $TooltipLabel

var slots = []
var selected_slot = -1

func _ready():
	print("InventoryDisplay: _ready called")
	
	# Try to automatically get reference to the inventory
	var character = get_parent().get_parent()
	print("InventoryDisplay: Parent of parent is: " + character.name)
	
	if has_node("Inventory"):
		inventory = get_node("Inventory")
		print("InventoryDisplay: Found Inventory node as direct child")
		
		# Connect signals from the inventory
		inventory.item_added.connect(_on_item_added)
		inventory.item_removed.connect(_on_item_removed)
		inventory.item_modified.connect(_on_item_modified)
		
		print("InventoryDisplay: Connected signals")
	else:
		print("InventoryDisplay: No Inventory node found!")
		if character:
			print("Available nodes under character: " + str(character.get_children()))
	
	# Get all slot nodes
	collect_slots()
	print("InventoryDisplay: Collected " + str(slots.size()) + " slots")
	
	# Initialize the tooltip
	tooltip.visible = false
	
	# Initial display update
	update_inventory_display()

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
	
	# Add debug print to see what items are being processed
	print("Inventory items: ", inventory.items)
	
	# Fill slots with inventory items
	for i in range(inventory.items.size()):
		if i >= slots.size():
			break
			
		var item = inventory.items[i]
		var slot = slots[i]
		
		# Add debug print for each item
		print("Processing item: ", item.id, " with stack count: ", item.stack_count)
		
		# Set item texture
		var texture_rect = slot.get_node("ItemTexture")
		texture_rect.texture = item.texture
		
		# Set stack count if applicable
		var stack_label = slot.get_node("StackLabel")
		if item.stackable and item.stack_count > 1:
			stack_label.text = str(item.stack_count)
			stack_label.visible = true
			# Add debug print to confirm label settings
			print("Setting stack label for ", item.id, " to: ", stack_label.text, " visible: ", stack_label.visible)
		else:
			stack_label.visible = false
func select_slot(index: int):
	# Deselect previous slot
	if selected_slot != -1 and selected_slot < slots.size():
		var prev_slot = slots[selected_slot]
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = slot_color
		normal_style.set_corner_radius_all(4)
		prev_slot.add_theme_stylebox_override("panel", normal_style)
	
	# Select new slot
	selected_slot = index
	
	if index != -1 and index < slots.size():
		var slot = slots[index]
		var selected_style = StyleBoxFlat.new()
		selected_style.bg_color = selected_slot_color
		selected_style.set_corner_radius_all(4)
		slot.add_theme_stylebox_override("panel", selected_style)
		
		# Show tooltip if item exists in inventory
		if inventory and index < inventory.items.size():
			show_tooltip(inventory.items[index])
		else:
			hide_tooltip()
	else:
		hide_tooltip()

func show_tooltip(item: Item):
	var tooltip_text = item.id
	
	if item.stackable:
		tooltip_text += " (" + str(item.stack_count) + "/" + str(item.max_stack) + ")"
	
	tooltip.text = tooltip_text
	tooltip.visible = true

func hide_tooltip():
	tooltip.visible = false

func _process(delta):
	# Update tooltip position to follow mouse
	if tooltip.visible:
		tooltip.global_position = get_viewport().get_mouse_position() + Vector2(10, 10)

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

func _on_slot_mouse_entered(index):
	if inventory and index < inventory.items.size():
		show_tooltip(inventory.items[index])

func _on_slot_mouse_exited(index):
	hide_tooltip()
