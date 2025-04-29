extends Node

var player_health: float = 100.0
var player_hunger: float = 100.0
var player_inventory: Array = []

func save_player_state(health: float, hunger: float, inventory: Array) -> void:
	player_health = health
	player_hunger = hunger
	player_inventory = inventory.duplicate(true)
	for item in inventory:
		if item is Resource:
			var copied_item = item.duplicate(true)
			player_inventory.append(copied_item)
		else:
			push_error("not Resource: ", item)

func load_player_state() -> Dictionary:
	return {
		"health": player_health,
		"hunger": player_hunger,
		"inventory": player_inventory.duplicate(true)
	}
