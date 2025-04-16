# food_item.gd
class_name FoodItem extends Item

@export var health_restore: int = 0
@export var hunger_restore: int = 0

func _init():
	item_type = ItemType.FOOD
	stackable = true
	max_stack_size = 99

func use(player) -> bool:
	# 恢复生命值和饥饿值
	player.restore_health(health_restore)
	player.restore_hunger(hunger_restore)
	return true
