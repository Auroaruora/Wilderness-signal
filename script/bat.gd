extends CharacterBody2D

@export var max_health: int = 100
@export var speed = 18  # Movement speed when chasing the player
@export var target : Node2D
@export var max_distance = 150 # Max distance between Bat and Player before Bat stops chase
@onready var sprite = $Sprite2D
@onready var health_bar = $BatHealthbar  # Ensure the Bat has a ProgressBar node
@onready var navigation_agent = $NavigationAgent2D

var current_health: int
var attack_distance = 40
var attack_damage = 10
var squash_speed = 10.0  # Controls how fast the squash effect happens
var squash_amount_x = 0.3  # How much to squash (30%)
var squash_amount_y = 0.1  # How much to squash (10%)
var time = 0.0  # Timer for oscillation
var player_in_range = false # If player is in attack range
var can_attack = true # If attack is off cooldown
var attack_cooldown = 1.0 # Seconds between attacks
var is_dead := false

func _ready():
	current_health = max_health
	update_health_bar()
	call_deferred("setup")
	pass
	
func setup():
	await get_tree().physics_frame
	# Get target position
	if target:
		navigation_agent.target_position = target.global_position

func _process(delta):
	add_to_group("enemy")
	time += delta * squash_speed
	var squash_factor_x = sin(time) * squash_amount_x
	var squash_factor_y = sin(time) * squash_amount_y
	
	sprite.scale = Vector2(1.0 + squash_factor_x, 1.0 - squash_factor_y)  # Squash effect

	# Update target position
	if target:
		navigation_agent.target_position = target.global_position
	
	# Stop navigating if close enough
	if navigation_agent.is_navigation_finished():
		return
	
	# Update navigation path
	var current_agent_position = global_position
	var next_path_position = navigation_agent.get_next_path_position()
	
	# Check target distance
	if current_agent_position.distance_to(navigation_agent.target_position) < max_distance:
		velocity = current_agent_position.direction_to(next_path_position) * speed
	else:
		velocity = Vector2i.ZERO
		
	# Move
	move_and_slide()
		
	# Attack
	if player_in_range && can_attack:
		attack_player()
		can_attack = false
		get_tree().create_timer(attack_cooldown).timeout.connect(func(): can_attack = true)



# Function to attack the player
func attack_player():
	if target and target.global_position.distance_to(global_position) < attack_distance:
		target.take_damage(attack_damage)  # Bat deals damage
		
# Take Damage Function
func take_damage(amount):
	current_health -= amount
	if current_health <= 0:
		die()
	update_health_bar()

func update_health_bar():
	if health_bar:
		health_bar.min_value = 0
		health_bar.max_value = max_health
		health_bar.value = current_health

func die():
	if is_dead:
		return
	is_dead = true
	get_node("/root/GameManager").enemy_died(global_position)
	await get_tree().process_frame
	queue_free()  # Bat disappears

func _on_enemy_hitbox_body_shape_entered(_body_rid: RID, body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	if body == target:
		player_in_range = true
func _on_enemy_hitbox_body_shape_exited(_body_rid: RID, body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	if body == target:
		player_in_range = false
