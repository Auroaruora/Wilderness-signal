extends CharacterBody2D


@onready var player = get_parent().find_child("Character")
@onready var sprite = $Sprite2D
@onready var progress_bar = $UI/ProgressBar
@onready var melee = get_node("FiniteStateMachine/MeleeAttack")
@onready var laser = get_node("FiniteStateMachine/Laser")


signal hit_player
signal hit_laser
 
var direction : Vector2
var DEF = 0
var is_active = false

var health = 100:
	set(value):
		health = value
		progress_bar.value = value
		if value <= 0:
			progress_bar.visible = false
			find_child("FiniteStateMachine").change_state("Death")
		elif value <= progress_bar.max_value / 2 and DEF == 0:
			DEF = 5
			find_child("FiniteStateMachine").change_state("ArmorBuff") 

func _ready():
	melee.hit_p.connect(melee_hit)
	laser.hit_l.connect(laser_hit)
	set_physics_process(false)
	progress_bar.modulate.a = 0.0
 
func _process(_delta):
	if not is_active:
		return

	direction = player.position - position
	if direction.x < 0:
		sprite.flip_h = true
	else:
		sprite.flip_h = false
	
 
func _physics_process(delta):
	if not is_active:
		return
	velocity = direction.normalized() * 40
	move_and_collide(velocity * delta)
	
func take_damage(damage_amount: int = 10):
	health -= damage_amount - DEF

func melee_hit():
	if not is_active:
		return
	if is_instance_valid(player):
		player.take_damage(5)
	
func laser_hit():
	if not is_active:
		return
	if is_instance_valid(player):
		player.take_damage(6)

func activate():
	is_active = true
	set_physics_process(true)
	set_process(true)
	visible = true
	progress_bar.modulate.a = 1.0
