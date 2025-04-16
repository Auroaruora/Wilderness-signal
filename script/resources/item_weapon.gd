class_name WeaponItem extends Item

enum WeaponType {
	SWORD,
	BOW,
	STAFF,
	AXE
}

@export var weapon_type: WeaponType
@export var damage: int = 0
@export var attack_speed: float = 1.0

func _init():
	item_type = ItemType.WEAPON
	stackable = false

func use(player) -> bool:
	# Equip the weapon
	player.equip_weapon(self)
	return true
