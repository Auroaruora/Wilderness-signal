# ToolItem.gd
class_name ToolItem
extends Item

@export var tool_strength: int = 1
@export var durability: int = 100
@export var max_durability: int = 100
@export_enum("Pickaxe", "Axe", "Shovel", "Hoe", "Hammer") var tool_type: String = "Pickaxe"
@export var efficiency: float = 1.0

func _init():
	item_type = ItemType.TOOL
	stackable = false

func use(character) -> bool:
	if character.has_method("equip_tool"):
		character.equip_tool(self)
		return true
	return false
	
func can_interact_with(object_type: String) -> bool:
	match tool_type:
		"Pickaxe":
			return object_type in ["rock", "ore", "mineral"]
		"Axe":
			return object_type in ["tree"]
		#"Shovel":
			#return object_type in ["dirt", "sand", "gravel"]
		#"Hoe":
			#return object_type in ["soil", "farmland"]
		#"Hammer":
			#return object_type in ["building", "construct"]
	return false
	
func decrease_durability(amount: int = 1) -> bool:
	durability = max(0, durability - amount)
	return durability > 0
