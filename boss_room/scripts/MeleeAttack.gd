extends State

signal hit_p

var attack_cooldown := 0.8
var can_attack := true

func enter():
	super.enter()
	animation_player.play("melee_attack")
 
func transition():
	if owner.direction.length() > 30:
		get_parent().change_state("Follow")

func attack_once():
	if can_attack:
		can_attack = false
		hit_p.emit()
		start_cooldown()

func start_cooldown():
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
