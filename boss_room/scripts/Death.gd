extends State
func enter():
	super.enter()
	animation_player.play("death")
	await animation_player.animation_finished
	spawn_exit()
	owner.queue_free()

func spawn_exit():
	var exit_scene = preload("res://boss_room/portal.tscn")
	var exit_instance = exit_scene.instantiate()
	owner.get_parent().add_child(exit_instance)
	exit_instance.global_position = owner.global_position + Vector2(0, -40)
	print("position: ", exit_instance.position)
