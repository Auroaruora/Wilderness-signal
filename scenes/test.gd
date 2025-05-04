extends Node2D  # or whatever your scene root extends

@onready var character = $Character
@onready var entrance = $Entrance
@onready var butterfly = $Butterfly

func _ready() -> void:
	# Setup butterfly with references
	butterfly.player_path = character.get_path()
	butterfly.entrance_node_path = entrance.get_path()
	
	# Connect signals
	butterfly.player_reached_destination.connect(_on_player_reached_destination)

func _on_player_reached_destination() -> void:
	# Optional: Play a celebration effect or show a message
	print("Player has been led to the entrance by the butterfly!")
