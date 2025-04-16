extends StaticBody2D

# Export variables that will appear in the Inspector
@export var health = 3

# Track if the tree has been cut
var is_cut = false

# Onready variables to get the child nodes
@onready var tree_sprite = $TreeSprite
@onready var stump_sprite = $StumpSprite

func _ready():
	# Make sure the tree sprite is visible and stump is hidden
	tree_sprite.visible = true
	stump_sprite.visible = false

# Function to call when tree is hit
func take_damage(amount):
	# Only take damage if tree hasn't been cut yet
	if is_cut:
		return
		
	health -= amount
	
	# Visual feedback when tree is hit
	tree_sprite.modulate = Color(1, 0.5, 0.5)  # Flash red
	await get_tree().create_timer(0.1).timeout
	tree_sprite.modulate = Color(1, 1, 1)  # Return to normal
	
	if health <= 0:
		cut_down()

# Function to cut down the tree
func cut_down():
	# Switch from tree to stump sprite
	tree_sprite.visible = false
	stump_sprite.visible = true
	
	is_cut = true
	
	# You can add more code here later to spawn wood items
