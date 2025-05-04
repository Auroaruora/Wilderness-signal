# GlobalData.gd
extends Node

# Persistent player data
var player_inventory_data: Array = []
var player_health: float = 0
var player_hunger: float = 0
var player_position: Vector2 = Vector2.ZERO

## Save inventory data
#func save_inventory(inventory: Inventory):
	#player_inventory_data.clear()
	#
	## Store relevant item data
	#for item in inventory.items:
		#var item_data = {
			#"id": item.id,
			#"name": item.name,
			#"item_type": item.item_type,
			#"stackable": item.stackable,
			#"stack_count": item.stack_count,
			#"max_stack": item.max_stack,
			## Additional type-specific data
			#"additional_data": {}
		#}
		#
		## Add type-specific data based on item type
		#match item.item_type:
			#Item.ItemType.FOOD:
				#var food_item = item as FoodItem
				#item_data["additional_data"] = {
					#"health_restore": food_item.health_restore,
					#"stamina_restore": food_item.stamina_restore,
					#"hunger_restore": food_item.hunger_restore,
					#"thirst_restore": food_item.thirst_restore,
					#"buff_duration": food_item.buff_duration,
					#"buffs": food_item.buffs
				#}
			#
			#Item.ItemType.TOOL:
				#var tool_item = item as ToolItem
				#item_data["additional_data"] = {
					#"tool_type": tool_item.tool_type,
					#"tool_strength": tool_item.tool_strength,
					#"durability": tool_item.durability,
					#"max_durability": tool_item.max_durability,
					#"efficiency": tool_item.efficiency
				#}
			#
			#Item.ItemType.WEAPON:
				#var weapon_item = item as WeaponItem
				#item_data["additional_data"] = {
					#"weapon_type": weapon_item.weapon_type,
					#"damage": weapon_item.damage,
					#"attack_speed": weapon_item.attack_speed,
					#"range": weapon_item.range,
					#"durability": weapon_item.durability,
					#"max_durability": weapon_item.max_durability,
					#"effects": weapon_item.effects
				#}
		#
		#player_inventory_data.append(item_data)
	#
	#print("Inventory saved: ", player_inventory_data)
#
## Load inventory data
#func load_inventory(inventory: Inventory):
	## Clear existing inventory
	#inventory.items.clear()
	#
	## Recreate items from saved data
	#for item_data in player_inventory_data:
		#var new_item = create_item_from_data(item_data)
		#
		#if new_item:
			#inventory.add_item(new_item)
	#
	#print("Inventory loaded: ", inventory.items)
#
## Helper method to create items from saved data
# GlobalData.gd
func save_inventory(inventory: Inventory):
	player_inventory_data.clear()
	
	for item in inventory.items:
		var item_data = {
			"resource_path": item.resource_path,  # Save the full resource path
			"stack_count": item.stack_count,
			"stackable": item.stackable
		}
		
		player_inventory_data.append(item_data)
	
	print("Inventory saved: ", player_inventory_data)

func load_inventory(inventory: Inventory):
	# Clear existing inventory
	inventory.items.clear()
	
	# Recreate items from saved data
	for item_data in player_inventory_data:
		# Load the entire resource
		var item = load(item_data["resource_path"])
		
		if item:
			# Restore stack information
			if "stack_count" in item_data:
				item.stack_count = item_data["stack_count"]
			
			inventory.add_item(item)
	
	print("Inventory loaded: ", inventory.items)

func create_item_from_data(item_data: Dictionary) -> Item:
	var item: Item = null
	
	# Add a method to create items by ID
	item = create_item_by_id(item_data["id"])
	
	if not item:
		push_error("Failed to create item with ID: " + item_data["id"])
		return null
	
	# Override item properties with saved data
	item.stackable = item_data["stackable"]
	item.stack_count = item_data["stack_count"]
	item.max_stack = item_data["max_stack"]
	
	# Add type-specific data based on item type
	match item_data["item_type"]:
		Item.ItemType.FOOD:
			var food_item = item as FoodItem
			if food_item:
				food_item.health_restore = item_data["additional_data"].get("health_restore", 0)
				food_item.stamina_restore = item_data["additional_data"].get("stamina_restore", 0)
				food_item.hunger_restore = item_data["additional_data"].get("hunger_restore", 0)
				food_item.thirst_restore = item_data["additional_data"].get("thirst_restore", 0)
				food_item.buff_duration = item_data["additional_data"].get("buff_duration", 0.0)
				food_item.buffs = item_data["additional_data"].get("buffs", [])
		
		Item.ItemType.TOOL:
			var tool_item = item as ToolItem
			if tool_item:
				tool_item.tool_type = item_data["additional_data"].get("tool_type", "Pickaxe")
				tool_item.tool_strength = item_data["additional_data"].get("tool_strength", 1)
				tool_item.durability = item_data["additional_data"].get("durability", 100)
				tool_item.max_durability = item_data["additional_data"].get("max_durability", 100)
				tool_item.efficiency = item_data["additional_data"].get("efficiency", 1.0)
		
		Item.ItemType.WEAPON:
			var weapon_item = item as WeaponItem
			if weapon_item:
				weapon_item.weapon_type = item_data["additional_data"].get("weapon_type", "Sword")
				weapon_item.damage = item_data["additional_data"].get("damage", 1)
				weapon_item.attack_speed = item_data["additional_data"].get("attack_speed", 1.0)
				weapon_item.range = item_data["additional_data"].get("range", 1.0)
				weapon_item.durability = item_data["additional_data"].get("durability", 100)
				weapon_item.max_durability = item_data["additional_data"].get("max_durability", 100)
				weapon_item.effects = item_data["additional_data"].get("effects", [])
	
	return item

# Method to create specific items by ID
func create_item_by_id(item_id: String) -> Item:
	# This is a centralized method to create items
	# You'll need to modify this to match your item creation logic
	match item_id:
		"pickaxe":
			var pickaxe = ToolItem.new()
			pickaxe.id = "pickaxe"
			pickaxe.name = "Pickaxe"
			pickaxe.tool_type = "Pickaxe"
			return pickaxe
		
		"axe":
			var axe = ToolItem.new()
			axe.id = "axe"
			axe.name = "Axe"
			axe.tool_type = "Axe"
			return axe
		
		"stone":
			var stone = MaterialItem.new()
			stone.id = "stone"
			stone.name = "Stone"
			return stone
		
		# Add more items as needed
		_:
			push_error("No item found with ID: " + item_id)
			return null

# Save player state before scene change
func save_player_state(player: Character):
	# Save inventory
	save_inventory(player.inventory)
	
	# Save health
	var health_system = player.get_node_or_null("HealthSystem")
	if health_system:
		player_health = health_system.current_health
		print("Health saved: ", player_health)
	
	# Save hunger
	var hunger_system = player.get_node_or_null("HungerSystem")
	if hunger_system:
		player_hunger = hunger_system.current_hunger
		print("Hunger saved: ", player_hunger)
	
	## Save other player states
	#player_health = player.health
	#player_position = player.global_position

func load_player_state(player: Character):
	# Load inventory
	load_inventory(player.inventory)
	
	# Load health
	var health_system = player.get_node_or_null("HealthSystem")
	if health_system:
		health_system.current_health = player_health
		health_system.emit_signal("health_changed", health_system.current_health)
		print("Health loaded: ", player_health)
	else:
		print("Warning: No HealthSystem found on player")
	
	# Load hunger
	var hunger_system = player.get_node_or_null("HungerSystem")
	if hunger_system:
		hunger_system.current_hunger = player_hunger
		hunger_system.emit_signal("hunger_changed", hunger_system.current_hunger)
		print("Hunger loaded: ", player_hunger)
	else:
		print("Warning: No HungerSystem found on player")
