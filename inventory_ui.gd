# TestInventorySlot.gd
extends CanvasLayer

@onready var inventory_slot = $InventorySlot

func _ready():
	# Load the existing resource
	var wood_item = load("res://resources/wood.tres") # Replace with actual path
	
	# Set the item to the slot
	inventory_slot.set_item(wood_item)
