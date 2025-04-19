class_name RepairableTower extends Node2D

@export var item_resource: Item = null

# Two sprites for different tower states
@onready var broken_sprite = $BrokenSprite
@onready var repaired_sprite = $RepairedSprite
@onready var interaction_area = $InteractionArea

@export var wood_required = 2
@export var interaction_distance = 30.0

var is_broken = true
var player_ref = null

func _ready():
	# Set initial state
	broken_sprite.visible = true
	repaired_sprite.visible = false

func _process(delta):
	# Check for player input when in range
	if player_ref and Input.is_action_just_pressed("interact") and is_broken:
		if is_player_close():
			attempt_repair()

func is_player_close() -> bool:
	return player_ref.is_close_to_object(global_position, interaction_distance)

func attempt_repair():
	# Check if player has wood
	if player_ref.inventory.get_stack_count("wood") >= wood_required:
		# Create a new action for repairing
		var repair_action = player_ref.CharacterAction.new(
			"hammer",
			func(): return true,  # Always allow this action once we reach this point
			func(): consume_wood_and_repair(),  # What happens on completion
			"hammer_"  # Animation prefix for "hammer_up", "hammer_down", etc.
		)
		
		# Determine facing direction relative to tower
		var direction = player_ref.get_interaction_direction(global_position)
		if direction == "left":
			player_ref.current_direction = player_ref.Direction.LEFT
		else:
			player_ref.current_direction = player_ref.Direction.RIGHT
		
		# Perform the hammering action
		player_ref.perform_generic_action(repair_action)

func consume_wood_and_repair():
	# Create a wood item to remove from inventory
	var wood_item = {
		"id": "wood",
		"stackable": true,
		"stack_count": wood_required,
		"max_stack": 99
	}
	
	# Remove wood from inventory (this needs to match your item structure)
	for i in range(wood_required):
		for item in player_ref.inventory.items:
			if item.id == "wood":
				if item.stack_count > 1:
					item.stack_count -= 1
				else:
					player_ref.inventory.remove_item(item)
				break
	
	# Repair the tower
	repair_tower()

func repair_tower():
	# Change sprite
	broken_sprite.visible = false
	repaired_sprite.visible = true
	is_broken = false
	
	# Optional: Play a repair sound
	# $RepairSound.play()

func _on_interaction_area_body_entered(body):
	if body is Character:  # Using the class_name from your Character script
		player_ref = body

#func _on_interaction_area_area_exited(body):
	#if body is Character and player_ref == body:
		#player_ref = null


func _on_interaction_area_body_exited(body):
	if body is Character and player_ref == body:
		player_ref = null
