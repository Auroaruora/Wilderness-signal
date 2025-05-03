# Item.gd (Base Class)
class_name Item
extends Resource

# Define all major item categories in the base class
enum ItemType {
	FOOD,
	TOOL,
	WEAPON,
	MATERIAL,
	#QUEST,
	#EQUIPMENT,
	#CONSUMABLE
}

@export var id: String
@export var name: String
@export var texture: Texture2D
@export var texture_path: String = ""
@export var item_type: ItemType
@export var stackable: bool = false
@export var stack_count: int = 1
@export var max_stack: int = 1
@export_multiline var description: String = ""
@export var value: int = 0  # For selling/buying

func _init():
	# Add a way to load texture if path is provided
	if texture_path and not texture:
		texture = load(texture_path)
		
func _get_property_list():
	var properties = []
	properties.append({
		"name": "texture_path",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_STORAGE
	})
	return properties	

func use(character) -> bool:
	# Base implementation does nothing
	# Override in child classes"res://resources/assets/consumable/wood.png"
	return false
	
func can_use() -> bool:
	# Check if the item can be used
	return true
	
func get_display_name() -> String:
	if stackable and stack_count > 1:
		return name + " (" + str(stack_count) + ")"
	return name
	
func get_item_texture() -> Texture2D:
	# Debug method to check texture
	print("Texture in resource: ", texture)
	return texture

func is_food() -> bool:
	return item_type == ItemType.FOOD
	
func is_tool() -> bool:
	return item_type == ItemType.TOOL
	
func is_weapon() -> bool:
	return item_type == ItemType.WEAPON
	
func is_material() -> bool:
	return item_type == ItemType.MATERIAL
	
func is_stackable() -> bool:
	return stackable
	
func add_to_stack(amount: int = 1) -> int:
	if not stackable:
		return amount
		
	var space_left = max_stack - stack_count
	var amount_to_add = min(amount, space_left)
	
	stack_count += amount_to_add
	return amount - amount_to_add  # Return remaining amount that didn't fit
	
func remove_from_stack(amount: int = 1) -> int:
	var amount_to_remove = min(amount, stack_count)
	stack_count -= amount_to_remove
	return amount_to_remove
