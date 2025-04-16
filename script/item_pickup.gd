# ItemPickup.gd - This is a generic script for all pickups
extends Area2D

class_name ItemPickup

# This will reference your resource (Axe.tres, etc.)
@export var item_resource: Resource
@onready var sprite = $Sprite2D

func _ready():
	# Set the sprite's texture from the resource
	if item_resource and "texture" in item_resource:
		sprite.texture = item_resource.texture

func _on_body_entered(body):
	if body.has_method("pickup_item"):
		if body.pickup_item(item_resource):
			queue_free()  # Remove the pickup after it's collected
