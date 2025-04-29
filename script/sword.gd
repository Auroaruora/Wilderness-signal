extends Area2D

var player_in_range = false
var attached = false

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	add_to_group("interactable")

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		UIPrompt.show_message("Press E to pick up")

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false

func interact():
	if player_in_range:
		var player = get_tree().get_nodes_in_group("player")[0]
		player.pickup_weapon(self)
func attack():
	$AnimationPlayer.play("swing")

func _process(delta):
	if attached:
		var mouse_pos = get_global_mouse_position()
		var target_angle = (mouse_pos - global_position).angle()
		rotation = lerp_angle(rotation, target_angle + PI/2, 20 * delta)
