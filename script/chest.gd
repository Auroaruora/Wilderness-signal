extends StaticBody2D

var player_in_range = false
var is_open = false

func _ready():
	$Area2D.connect("body_entered", Callable(self, "_on_Area2D_body_entered"))
	$Area2D.connect("body_exited", Callable(self, "_on_Area2D_body_exited"))
	add_to_group("interactable")

func _on_Area2D_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		UIPrompt.show_message("Press E to open")

func _on_Area2D_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false

func interact():
	if player_in_range and not is_open:
		$AnimatedSprite2D.play("open")
		is_open = true
		drop_weapon()
		remove_from_group("interactable")

func drop_weapon():
	var sword_scene = preload("res://scenes/pickable_item.tscn")
	var sword = sword_scene.instantiate()
	sword.global_position = global_position
	get_tree().current_scene.add_child(sword)
