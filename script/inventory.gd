# Inventory.gd
class_name Inventory
extends Node

signal item_added(item)
signal item_removed(item)
signal item_modified(item)
var items = []
@export var max_items = 10

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

# Function to print out the entire inventory contents
func print_inventory():
	if items.size() == 0:
		print("Inventory is empty.")
		return
	
	print("== INVENTORY CONTENTS ==")
	print("Items: " + str(items.size()) + "/" + str(max_items))
	
	# Group items by ID for better organization
	var grouped_items = {}
	
	for item in items:
		if not grouped_items.has(item.id):
			grouped_items[item.id] = {
				"item": item,
				"count": 1 if not item.stackable else item.stack_count
			}
		elif not item.stackable:
			# For non-stackable items, count separately
			grouped_items[item.id]["count"] += 1
	
	# Display all items
	for id in grouped_items:
		var item_data = grouped_items[id]
		var item = item_data["item"]
		var count = item_data["count"]
		
		var stack_info = ""
		if item.stackable:
			stack_info = " (Stack: " + str(count) + "/" + str(item.max_stack) + ")"
		else:
			stack_info = " (Quantity: " + str(count) + ")"
			
		print("- " + item.id + stack_info)
	
	print("========================")
	return grouped_items  # Return grouped items for potential UI use
