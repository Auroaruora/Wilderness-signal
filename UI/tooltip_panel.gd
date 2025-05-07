# TooltipPanel.gd
extends Panel

@onready var item_name_label = $MarginContainer/VBoxContainer/ItemNameLabel
@onready var stack_info_label = $MarginContainer/VBoxContainer/StackInfoLabel

# Initialize
func _ready():
	visible = false  # Start hidden

# Display item information
func display_item(item: Item):
	if not item:
		hide()
		return
	var inventory_display = get_parent()
	var slot_container = inventory_display.slot_container
	
	# Position above the slot container
	global_position = Vector2(
		slot_container.global_position.x + (slot_container.size.x / 2) - (size.x / 2),  # center horizontally
		slot_container.global_position.y - size.y - 10  # 10 pixels above
	)
	
	# Show the panel
	visible = true	
	# Set item name
	item_name_label.text = item.id
	print(item.id)
	
	# Set stack info if applicable
	if item.stackable:
		stack_info_label.text = "Stack: " + str(item.stack_count) + "/" + str(item.max_stack)
		stack_info_label.visible = true
	else:
		stack_info_label.visible = false
	
	# Show the panel
	show()
	print("TooltipPanel rect: ", get_global_rect())
	print("TooltipPanel visible: ", visible)
	queue_redraw()
# Clear the tooltip
func clear():
	item_name_label.text = ""
	stack_info_label.text = ""
	stack_info_label.visible = false
	hide()
