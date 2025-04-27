class_name MaterialItem
extends Item

## Define properties specific to crafting materials
#@export var crafting_tags: Array[String] = []  # Tags like "metal", "wood", "gem" for recipe matching

func _init():
	# Set default item type to MATERIAL
	item_type = ItemType.MATERIAL
	# Materials are typically stackable
	stackable = true
	max_stack = 99  # Default stack size

# Override use function to allow materials to be used in crafting
func use(character) -> bool:
	# Check if character has active recipe that uses this material
	if character.has_method("get_active_recipe"):
		var recipe = character.get_active_recipe()
		if recipe and recipe.can_use_material(self):
			recipe.add_material(self)
			remove_from_stack(1)  # Use one from the stack
			return true
	return false

## Helper method to check if material has a specific crafting tag
#func has_tag(tag: String) -> bool:
	#return tag in crafting_tags
	
## For checking if this material matches a specific recipe requirement
#func matches_requirement(requirement: Dictionary) -> bool:
	## Check if this material has the required ID or tags
	#if "id" in requirement and requirement.id == id:
		#return true
		#
	#if "tags" in requirement:
		#for tag in requirement.tags:
			#if tag in crafting_tags:
				#return true
				#
	#return false
