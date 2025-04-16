# item.gd
class_name Item extends Resource

# Basic properties
@export var id: String = ""  # Unique identifier, also used as display name
@export var icon: Texture2D 
@export var description: String = ""
@export var stackable: bool = false
@export var max_stack_size: int = 1

# Item type enum
enum ItemType {
	ARMOR,
	WEAPON,
	MATERIAL,
	PLACEABLE,
	FOOD
}
@export var item_type: ItemType = ItemType.MATERIAL

# Basic methods
func use(player) -> bool:
	# Base use method, will be overridden by subclasses
	print("Using item: ", id)
	return true
