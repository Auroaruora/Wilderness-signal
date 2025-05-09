extends State
@onready var pivot = $"../../Pivot"
var can_transition: bool = false
var players_inside := []
var laser_timer: Timer = null
 
signal hit_l

func enter():
	super.enter()
	await play_animation("laser_cast")
	var laser_area = pivot.get_node("LaserArea")
	if laser_area:
		laser_area.monitoring = true
		laser_area.body_entered.connect(_on_LaserArea_body_entered)
		laser_area.body_exited.connect(_on_LaserArea_body_exited)

		laser_timer = Timer.new()
		laser_timer.wait_time = 0.3
		laser_timer.one_shot = false
		laser_timer.autostart = true
		laser_timer.timeout.connect(_on_laser_tick)
		add_child(laser_timer)
	await play_animation("laser")
	if laser_area:
		laser_area.monitoring = false
		laser_area.body_entered.disconnect(_on_LaserArea_body_entered)
		laser_area.body_exited.disconnect(_on_LaserArea_body_exited)
	players_inside.clear()

	if laser_timer:
		laser_timer.queue_free()
	can_transition = true
 
func play_animation(anim_name):
	animation_player.play(anim_name)
	var sfx = get_parent().get_parent().get_node_or_null("Audio_laser")
	sfx.play()
	await animation_player.animation_finished
 
func set_target():
	pivot.rotation = (owner.direction - pivot.position).angle()
 
func transition():
	if can_transition:
		can_transition = false
		get_parent().change_state("Dash")

func _on_LaserArea_body_entered(body: Node):
	if body.name == "Character" and body not in players_inside:
		players_inside.append(body)
		hit_l.emit()

func _on_LaserArea_body_exited(body: Node):
	if body in players_inside:
		players_inside.erase(body)

func _on_laser_tick():
	for body in players_inside:
		if is_instance_valid(body):
			hit_l.emit()

func _on_laser_area_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_laser_area_body_exited(body: Node2D) -> void:
	pass # Replace with function body.
