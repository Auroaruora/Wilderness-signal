class_name MaterialItem extends Item

# Flag for crafting materials
@export var crafting_material: bool = true

func _init():
	item_type = ItemType.MATERIAL
	stackable = true
	max_stack_size = 99

func use(player) -> bool:
	# Materials typically can't be used directly
	return false
