extends State

@export var bullet_node: PackedScene
var can_transition: bool = false
 
func enter():
	super.enter()
	animation_player.play("range_attack")
	await animation_player.animation_finished
	var sfx = get_parent().get_parent().get_node_or_null("Audio_shoot")
	sfx.play()
	shoot()
	can_transition = true
 
func shoot():
	var bullet = bullet_node.instantiate()
	bullet.position = owner.position
	get_tree().current_scene.add_child(bullet)
 
func transition():
	if can_transition:
		can_transition = false
		get_parent().change_state("Dash")
