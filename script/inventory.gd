# Inventory.gd
class_name Inventory
extends Node

signal item_added(item)
signal item_removed(item)
signal item_modified(item)
var items = []
@export var max_items = 10
var current_selected_item = 0  # Default to first slot

# Updated select_item function in Inventory
func select_item(index):
	if index >= 0 and index < max_items:
		# Make sure the index is valid (within max_items)
		current_selected_item = index
		
		# Print the current selection status immediately
		print_selection_status()
		
		# Emit signal with the item (or null if slot is empty)
		var selected_item = items[index] if index < items.size() else null
		emit_signal("item_modified", selected_item)
		return true
	return false

# Function to return the currently selected item or null if selected slot is empty
func get_selected_item():
	# Check if the selected index is valid and has an item
	if current_selected_item >= 0 and current_selected_item < items.size():
		return items[current_selected_item]
	
	# Return null if the selected slot is empty or invalid
	return null

# Function to get the index of the currently selected slot
func get_selected_index():
	return current_selected_item	

func add_item(item):
	# First check if we can stack this item
	if item.stackable:
		# Look for existing stack of this item
		for existing_item in items:
			if existing_item.id == item.id and existing_item.stackable:
				# Found existing stack, check if we can add to it
				if existing_item.stack_count < existing_item.max_stack:
					existing_item.stack_count += 1
					emit_signal("item_added", existing_item)
					return true
	
	# If we can't stack or no existing stack found, add as new item
	if items.size() < max_items:
		items.append(item)
		emit_signal("item_added", item)
		return true
	return false
	
func remove_item(item, amount = 1):
	# Find the item in the inventory
	for existing_item in items:
		if existing_item.id == item.id:
			if existing_item.stackable:
				# Check if there are enough items in the stack
				if existing_item.stack_count < amount:
					return false
				
				# For stackable items, reduce stack count
				existing_item.stack_count -= amount
				
				# If stack count reaches 0, remove the item completely
				if existing_item.stack_count == 0:
					items.erase(existing_item)
				
				emit_signal("item_removed", existing_item)
				return true
			else:
				# For non-stackable items, ensure we have the item
				items.erase(existing_item)
				emit_signal("item_removed", existing_item)
				return true
	
	return false
	
func has_item(item_id):
	for item in items:
		if item.id == item_id:
			return true
	return false
	
func get_stack_count(item_id):
	for item in items:
		if item.id == item_id:
			return item.stack_count
	
	return 0

# New helper function to print selection status
func print_selection_status():
	var is_empty = current_selected_item >= items.size()
	print("Selected slot: " + str(current_selected_item) + 
		  (" (empty)" if is_empty else 
		   " (" + items[current_selected_item].id + ")"))

# Updated print_inventory function using get_selected_item()
func print_inventory():
	# Get the currently selected item and index
	var selected_item = get_selected_item()
	var selected_index = get_selected_index()
	
	if items.size() == 0:
		print("Inventory is empty.")
		print("Selected slot: " + str(selected_index) + " (empty)")
		return
	
	print("== INVENTORY CONTENTS ==")
	print("Items: " + str(items.size()) + "/" + str(max_items))
	
	# Display all items with their slot index
	for i in range(items.size()):
		var item = items[i]
		var stack_info = ""
		if item.stackable:
			stack_info = " (Stack: " + str(item.stack_count) + "/" + str(item.max_stack) + ")"
		
		# Check if this item is selected
		var selected_marker = ""
		if i == selected_index:
			selected_marker = " [SELECTED]"
			
		print("Slot " + str(i) + ": " + item.id + stack_info + selected_marker)
	
	# Show empty slots
	for i in range(items.size(), max_items):
		var selected_marker = ""
		if i == selected_index:
			selected_marker = " [SELECTED]"
		print("Slot " + str(i) + ": empty" + selected_marker)
	
	# Print the current selection status
	print("Selected slot: " + str(selected_index) + 
		  (" (empty)" if selected_item == null else 
		   " (" + selected_item.id + ")"))
	
	print("========================")
