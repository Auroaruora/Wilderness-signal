class_name ArmorItem extends Item

enum ArmorType {
	HELMET,
	CHESTPLATE,
	LEGGINGS,
	BOOTS
}

@export var armor_type: ArmorType
@export var defense_value: int = 0

func _init():
	item_type = ItemType.ARMOR
	stackable = false

func use(player) -> bool:
	# Equip the armor
	player.equip_armor(self)
	return true
