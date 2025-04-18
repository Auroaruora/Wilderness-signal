# InventorySlot.gd
class_name InventorySlot
extends Panel

# Export the item resource so it can be set in the editor
@export var item_resource: Item = null

# References to child nodes
@onready var background_sprite = $BackgroundSprite
@onready var item_sprite = $ItemSprite
@onready var stack_label = $Number

func _ready():
	# Initialize with the exported resource if available
	if item_resource:
		set_item(item_resource)
	else:
		clear_slot()

# Update the slot with a new item
func set_item(new_item: Item):
	item_resource = new_item
	
	if item_resource == null:
		clear_slot()
		return
	
	# Set the item texture
	item_sprite.texture = item_resource.texture
	item_sprite.visible = true
	
	# Update stack count label if stackable
	if item_resource.stackable and item_resource.stack_count > 1:
		stack_label.text = str(item_resource.stack_count)
		stack_label.visible = true
	else:
		stack_label.visible = false

# Clear the slot (make it empty)
func clear_slot():
	item_resource = null
	item_sprite.texture = null
	item_sprite.visible = false
	stack_label.visible = false

# Check if slot is empty
func is_empty() -> bool:
	return item_resource == null
