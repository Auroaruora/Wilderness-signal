extends Node2D
func _ready():
	var state = Global.load_player_state()
	

	var dungeon_player = $Character

	dungeon_player.get_node_or_null("HealthSystem").current_health = state["health"]

	dungeon_player.get_node_or_null("HungerSystem").current_hunger = state["hunger"]
	
	dungeon_player.inventory.items = []
	for item in state["inventory"]:
		dungeon_player.inventory.items.append(item.duplicate(true))  # ✅ 深拷贝

	dungeon_player.inventory_display.update_inventory_display()
