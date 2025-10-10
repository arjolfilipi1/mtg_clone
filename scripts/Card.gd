extends Control
class_name Card
var card_index = 10
var mana_cost 
var Mana_creation
var card_data = {}
var player_controled = false
var card_location
var is_creature: bool
var face_up: bool = false
#dragging 
var dragging = false
var position_before_drag: Vector2
var rotation_before_drag
var offset: Vector2 = Vector2.ZERO
var board_pos:Area2D = null
var tapped := false
var has_summoning_sickness := false
var summoned_on_turn:int 
	
var hover_scale = Vector2(1.2, 1.2)  # scale when hovered
var normal_scale = Vector2(1.0, 1.0)
var duration:float = 0.2  # seconds for the tween
var highlightTween: Tween
var controller : Player
#signal clicked()
var parts_highlighted:= false
var is_card = true
var mana_tween: Tween
var card_name : String
@onready var visual : Node = $vizual
@onready var movement: Node =  $movement

#add other cecks later
func  can_attack() :
	if card_location == "field" and has_summoning_sickness == false:
		return true
	return false
#add other cecks later
func  can_be_attacked() :
	if card_location == "field" :
		return true
	return false

func setup(data,players_card,_controller):
	visual = $vizual
	visual.card = self
	player_controled = players_card
	card_data = data
	controller = _controller
	if controller.is_human:
		face_up = true
	card_name = card_data['name']
	mana_cost = card_data['mana_cost']
	visual.set_background_color()
	is_creature = card_data['type'] == "Creature"
	Mana_creation = card_data['Mana_creation']
	var new_texture = load("res://assets/art/" + data['image'])
	visual.set_card_art(new_texture)
	# Update visuals (mana cost, power, etc.)
	#visual.setup()
	
func hilight_on():
	movement.highlighted = true
	self._on_mouse_entered()
	
func hilight_off():
	self._on_mouse_exited()

func _ready():
	await get_tree().process_frame
	visual.add_mana_symbols()
	visual.set_range()
	#self.pivot_offset = self.size / 2
	scale = normal_scale
	#highlightTween = create_tween()
	

func _on_mouse_entered():
	visual._on_mouse_entered()

func _on_mouse_exited():
	if not parts_highlighted:
		movement.highlighted = false
	
	self.z_index = card_index
	

func get_power():
	return card_data.get("power", 0)

func get_toughness():
	return card_data.get("toughness", 0)


func _on_gui_input(event: InputEvent) -> void:
	movement.on_click(event)



func check_drop_area():
	var mouse_pos = get_global_mouse_position()
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	if not can_be_payed():
		return false
	parameters.position= mouse_pos
	parameters.collide_with_areas = true
	parameters.collide_with_bodies = false
	parameters.collision_mask = 0xFFFFFFFF
	var result = space_state.intersect_point(parameters)
	
	for hit in result:
		var collider = hit.collider
		if collider is Area2D and collider.is_in_group("player_slots"):
			board_pos =  collider
			print("Dropped on Area2D:", collider.name)
			movement.play_card_to_board(collider,collider.scew_dict[collider.name])
			return
	dragging = false
	controller.player_hand.reset()

func can_be_payed() -> bool:
	var mana_pool = controller.mana_pool

	var pool = mana_pool.duplicate()
	
	for color in mana_cost.keys():
		var required = mana_cost[color]
		var available = pool.get(color, 0)
		
		if available >= required:
			# Use same-color mana
			pool[color] -= required
		else:
			# Calculate remaining cost
			var remaining = required - available
			pool[color] = 0
			
			# Calculate how much more we need in other colors (2:1 rate)
			var substitute_needed = remaining * 2
			var substitute_pool = 0
			
			for other_color in pool.keys():
				if other_color == color or other_color == "generic":
					continue
				substitute_pool += pool[other_color]
			
			if substitute_pool < substitute_needed:
				return false  # Not enough alternate mana
			
			# Spend substitute mana
			var to_spend = substitute_needed
			for other_color in pool.keys():
				if other_color == color or other_color == "generic":
					continue
				var usable = min(pool[other_color], to_spend)
				pool[other_color] -= usable
				to_spend -= usable
				if to_spend == 0:
					break
	if is_creature:
		return true
	else:
		return false
func _process(_delta: float) -> void:
	if TurnManager.highlighted != self:
		movement.animate_scale(normal_scale)
	
	if  summoned_on_turn == TurnManager.turn:
		pass
		#has_summoning_sickness = true
	else:
		has_summoning_sickness = false
	if (movement.highlighted and  card_location == "hand" ) or (movement.highlighted and  card_location == "field") :
		z_index = card_index + 10
	elif TurnManager.highlighted != self:
		self.z_index = card_index
		
