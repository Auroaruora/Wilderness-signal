# FoodItem.gd
class_name FoodItem
extends Item

@export var health_restore: int = 0
@export var stamina_restore: int = 0
@export var hunger_restore: int = 0
@export var thirst_restore: int = 0
@export var buff_duration: float = 0.0
@export var buffs: Array[String] = []

func _init():
	item_type = ItemType.FOOD
	stackable = true
	max_stack = 10

func use(character) -> bool:
	if character.has_method("restore_health"):
		print("resotring health")
		character.restore_health(health_restore)
	
	if character.has_method("restore_stamina"):
		character.restore_stamina(stamina_restore)
	
	if character.has_method("restore_hunger"):
		print("resotring hunger")
		character.restore_hunger(hunger_restore)
	
	if character.has_method("restore_thirst"):
		character.restore_thirst(thirst_restore)
	
	if buffs.size() > 0 and character.has_method("apply_buffs"):
		character.apply_buffs(buffs, buff_duration)
	
	return true
	
