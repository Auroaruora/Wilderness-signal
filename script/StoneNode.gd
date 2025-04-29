extends Entity
class_name StoneNode

@onready var stone_sprite = $StoneSprite

@export var pickable_stone_scene: PackedScene
@export var stone_resource: Resource
@export var interaction_distance = 40.0

var is_harvested = false
var player_ref = null

func _ready():
	add_to_group("stones")
	stone_sprite.visible = true
	print("Stone initialized")

func _on_interaction_area_body_entered(body):
	if body is Character:
		player_ref = body

func _on_interaction_area_body_exited(body):
	if body is Character and player_ref == body:
		player_ref = null

func _unhandled_input(event):
	if player_ref and not is_harvested and is_player_close():
		if event.is_action_pressed("interact"):
			if player_ref.inventory.get_selected_item_name() == "pickaxe":
				player_ref.attempt_action("pickaxe")
				await get_tree().create_timer(0.1).timeout
				harvest_stone()
				get_viewport().set_input_as_handled()

func is_player_close() -> bool:
	return player_ref.is_close_to_object(global_position, interaction_distance)

func harvest_stone():
	if is_harvested:
		return
	
	is_harvested = true
	
	drop_stone_items()
	
	await get_tree().create_timer(0.3).timeout
	remove()

func drop_stone_items():
	var stone_item = pickable_stone_scene.instantiate()
	stone_item.item_resource = stone_resource
	
	var offset_x = randf_range(-20, 20)
	var offset_y = randf_range(-20, 20)
	stone_item.global_position = global_position + Vector2(offset_x, offset_y)
	
	get_parent().add_child(stone_item)

func save():
	return {
		"position": {
			"x": position.x,
			"y": position.y
		},
		"is_harvested": is_harvested
	}

func load_state(state_data):
	if state_data.has("position"):
		position = Vector2(state_data.position.x, state_data.position.y)
	
	if state_data.get("is_harvested", false):
		remove()
