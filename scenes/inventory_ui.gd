# InventoryUI.gd
class_name InventoryUI
extends Control

# Reference to the actual inventory data
var inventory: Inventory

# Reference to the grid container that will hold all our slots
@onready var grid_container = $MarginContainer/GridContainer
@onready var selected_item_info = $SelectedItemPanel/VBoxContainer/ItemInfo

# Preload the slot scene
@export var slot_scene: PackedScene

# Currently selected slot and item
var selected_slot = null
var selected_item: Item = null

func _ready():
	# Hide the selected item panel initially
	$SelectedItemPanel.visible = false
	
	# Connect to the inventory signals
	if inventory:
		inventory.item_added.connect(_on_item_added)
		inventory.item_removed.connect(_on_item_removed)
		
		# Create the initial slots
		_setup_inventory_slots()

# Set the inventory this UI will display
func set_inventory(new_inventory: Inventory):
	# Disconnect from old inventory if it exists
	if inventory:
		if inventory.item_added.is_connected(_on_item_added):
			inventory.item_added.disconnect(_on_item_added)
		if inventory.item_removed.is_connected(_on_item_removed):
			inventory.item_removed.disconnect(_on_item_removed)
	
	# Set the new inventory
	inventory = new_inventory
	
	# Connect to the new inventory
	if inventory:
		inventory.item_added.connect(_on_item_added)
		inventory.item_removed.connect(_on_item_removed)
		
		# Setup the UI with the new inventory
		_setup_inventory_slots()

# Create all the inventory slots
func _setup_inventory_slots():
	# Clear existing slots first
	for child in grid_container.get_children():
		child.queue_free()
	
	# Create slots for the max inventory size
	for i in range(inventory.max_items):
		var slot_instance = slot_scene.instantiate()
		grid_container.add_child(slot_instance)
		
		# Connect to the slot's signals
		slot_instance.item_selected.connect(_on_slot_selected)
	
	# Update all slots with items
	_update_all_slots()

# Update all slots to reflect the current inventory
func _update_all_slots():
	# Get all slots
	var slots = grid_container.get_children()
	
	# Clear all slots first
	for slot in slots:
		slot.clear_slot()
	
	# Add items to slots
	for i in range(inventory.items.size()):
		if i < slots.size():
			slots[i].set_item(inventory.items[i])

# Called when an item is added to the inventory
func _on_item_added(item: Item):
	_update_all_slots()

# Called when an item is removed from the inventory
func _on_item_removed(item: Item):
	_update_all_slots()
	
	# If the removed item was selected, clear the selection
	if selected_item == item:
		_clear_selection()

# Called when a slot is selected
func _on_slot_selected(item: Item, slot):
	selected_item = item
	selected_slot = slot
	
	# Show the item info panel
	$SelectedItemPanel.visible = true
	
	# Update the item info
	selected_item_info.text = "Item: " + item.id
	if item.stackable:
		selected_item_info.text += "\nStack: " + str(item.stack_count) + "/" + str(item.max_stack)

# Clear the current selection
func _clear_selection():
	selected_item = null
	selected_slot = null
	$SelectedItemPanel.visible = false
