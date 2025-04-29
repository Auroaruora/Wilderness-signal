extends Area2D

func _ready():
	if has_node("AnimatedSprite2D"):
		print("AnimationPlayer found, playing 'default' animation")
		$AnimatedSprite2D.play("default")
	else:
		print("AnimationPlayer not found!")
	collision_layer = 1
	collision_mask = 1
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	print("Body entered: ", body)
	if body.is_in_group("player"):
		print("Player detected, showing victory popup")
		show_victory_popup()

func show_victory_popup():
	var popup = preload("res://scenes/VictoryPopup.tscn").instantiate()
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	get_tree().root.add_child(canvas)
	canvas.add_child(popup)
