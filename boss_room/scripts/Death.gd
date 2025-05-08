extends State
@export var pickable_blueprint_scene: PackedScene
@export var pickable_antenna_scene: PackedScene
@export var blueprint_resource: Resource
@export var antenna_resource: Resource
var death_sequence_started = false

func enter():
	# Only proceed if death sequence hasn't started yet
	if death_sequence_started:
		return
		
	death_sequence_started = true
	super.enter()
	animation_player.play("death")
	await animation_player.animation_finished
	spawn_exit()
	drop_boss_loot()
	owner.queue_free()

func spawn_exit():
	var exit_scene = preload("res://boss_room/portal.tscn")
	var exit_instance = exit_scene.instantiate()
	owner.get_parent().add_child(exit_instance)
	exit_instance.global_position = owner.global_position + Vector2(0, -40)
	print("position: ", exit_instance.position)
	
func drop_boss_loot(offset: Vector2 = Vector2.ZERO):
	print("Dropping blueprint item")
	var blueprint_item = pickable_blueprint_scene.instantiate()
	
	# Assign the ore resource to the pickable item
	blueprint_item.item_resource = blueprint_resource
	owner.get_parent().add_child(blueprint_item)
	blueprint_item.global_position = owner.global_position + Vector2(0, 20)
	print("blueprint item added to scene")
		
	var antenna_item = pickable_antenna_scene.instantiate()
	
	# Assign the ore resource to the pickable item
	antenna_item.item_resource = antenna_resource
	owner.get_parent().add_child(antenna_item)
	antenna_item.global_position = owner.global_position + Vector2(0, 22)
	print("blueprint item added to scene")
