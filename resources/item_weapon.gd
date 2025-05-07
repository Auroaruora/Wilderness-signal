# WeaponItem.gd
class_name WeaponItem
extends Item

@export var damage: int = 1
@export var attack_speed: float = 1.0
@export var range: float = 1.0
@export var durability: int = 100
@export var max_durability: int = 100
@export_enum("Sword", "Axe", "Bow", "Staff", "Dagger") var weapon_type: String = "Sword"
@export var effects: Array[String] = []

func _init():
	item_type = ItemType.WEAPON
	stackable = false

func use(character) -> bool:
	if character.has_method("attack"):
		character.attack()
		decrease_durability(1)
		return true
	return false
	
func get_dps() -> float:
	return damage * attack_speed
	
func decrease_durability(amount: int = 1) -> bool:
	durability = max(0, durability - amount)
	return durability > 0
	
func repair(amount: int) -> void:
	durability = min(max_durability, durability + amount)
	
