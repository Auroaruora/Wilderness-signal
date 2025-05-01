extends Node

var player_position: Vector2
var player_inventory: Array

func save_player_state(position: Vector2, inventory: Array):
	player_position = position
	player_inventory = inventory
