extends Area2D


@onready var animated_sprite = $AnimatedSprite2D
@onready var player = get_parent().find_child("Character")
 
var acceleration: Vector2 = Vector2.ZERO 
var velocity: Vector2 = Vector2.ZERO
var bullet_speed: float = 1000
 
func _physics_process(delta):
 
	acceleration = (player.position - position).normalized() * bullet_speed
 
	velocity += acceleration * delta
	rotation = velocity.angle()
 
	velocity = velocity.limit_length(150)
 
	position += velocity * delta
	
	await get_tree().create_timer(2).timeout
	queue_free()
 
func _on_body_entered(body):
	if body.name == "Character" and body.has_method("take_damage"):
		body.take_damage(15)
		print("Bullet hit:", body.name)
		queue_free()
