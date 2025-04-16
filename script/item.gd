# Item.gd
class_name Item
extends Resource

@export var id: String
@export var texture: Texture2D
@export var stackable: bool = false
@export var stack_count: int = 1
@export var max_stack: int = 1

#func _init(p_id = "", p_name = "", p_texture = null, p_stackable = false, p_max_stack = 1):
	#id = p_id
	#texture = p_texture
	#stackable = p_stackable
	#max_stack = p_max_stack
