class_name PlaceableItem extends Item

# Scene to instantiate when placed
@export var placeable_scene: PackedScene

func _init():
	item_type = ItemType.PLACEABLE
	stackable = true
	max_stack_size = 99

func use(player) -> bool:
	# Try to place the item
	return player.place_item(self)
