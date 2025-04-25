class_name PlayerCamera extends Camera2D

@export var camera_target_path: NodePath

var camera_target: Node2D

var dragging: bool = false
var last_mouse_pos: Vector2 = Vector2.ZERO

func _ready():
	if camera_target_path and has_node(camera_target_path):
		camera_target = get_node(camera_target_path) as Node2D
	make_current()

func _process(_delta):
	if camera_target:
		if not dragging:
			global_position = camera_target.global_position

	if Input.is_action_just_pressed("debug_zoom_in"):
		zoom *= 1.1
	elif Input.is_action_just_pressed("debug_zoom_out"):
		zoom *= 0.9

	if Input.is_action_just_pressed("debug_drag_camera"):
		dragging = true
		last_mouse_pos = get_global_mouse_position()
	elif Input.is_action_just_released("debug_drag_camera"):
		dragging = false

	if dragging:
		var mouse_pos = get_global_mouse_position()
		global_position -= (mouse_pos - last_mouse_pos)
		last_mouse_pos = mouse_pos
