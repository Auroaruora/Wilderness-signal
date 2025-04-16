class_name Character extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var inventory = $Inventory

@export var speed: float = 100.0
@export var acceleration: float = 800.0
@export var friction: float = 1000.0

func _ready() -> void:
	animated_sprite.play("idle_down")

func _physics_process(delta: float) -> void:
	var direction: Vector2 = Input.get_vector("run_left", "run_right", "run_up", "run_down")
	velocity = direction * speed
	
	handle_animations()
	
	move_and_slide()
	
func handle_animations() -> void:
	if velocity != Vector2.ZERO:
		if velocity.x < 0:
			animated_sprite.play("run_left")
		elif velocity.x > 0:
			animated_sprite.play("run_right")
		elif velocity.y < 0:
			animated_sprite.play("run_up")
		else:
			animated_sprite.play("run_down")
	else:

		var current_anim = animated_sprite.animation
		if current_anim == "run_left":
			animated_sprite.play("idle_left")
		elif current_anim == "run_right":
			animated_sprite.play("idle_right")
		elif current_anim == "run_up":
			animated_sprite.play("idle_up")
		elif current_anim == "run_down" || current_anim == "":
			animated_sprite.play("idle_down")
		elif current_anim.begins_with("idle_"):
			pass
		else:
			animated_sprite.play("idle_down")
			
func pickup_item(item):
	var success = inventory.add_item(item)
	inventory.print_inventory()
	return success
	
