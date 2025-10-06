extends Control
class_name Card
var card_index = 10
var mana_cost 
var Mana_creation
var card_data = {}
var player_controled = false
var card_location
var unique_material
var is_creature: bool
var face_up: bool = false
#dragging 
var dragging = false
var position_before_drag
var rotation_before_drag
var offset: Vector2 = Vector2.ZERO
var board_pos:Area2D = null
var tapped := false
var has_summoning_sickness := false
var summoned_on_turn 
	
var hover_scale = Vector2(1.2, 1.2)  # scale when hovered
var normal_scale = Vector2(1.0, 1.0)
var duration = 0.2  # seconds for the tween
var highlightTween: Tween
var background: Sprite2D
var controller : Player
#signal clicked()
var parts_highlighted:= false
var is_card = true
var mana_tween
var card_name : String
@onready var visual : Node = $vizual
@onready var m_container: HBoxContainer = $SubViewportContainer/SubViewport/ManaCostContainer
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
		$Summoning_sickness.show()
	$SubViewportContainer/SubViewport/Panel/Name.text = card_data['name']
	card_name = card_data['name']
	$SubViewportContainer/SubViewport/Panel/Health.text = str(card_data['toughness'])
	mana_cost = card_data['mana_cost']
	visual.set_background_color()
	is_creature = card_data['type'] == "Creature"
	Mana_creation = card_data['Mana_creation']
	var new_texture = load("res://assets/art/" + data['image'])
	visual.set_card_art(new_texture)
	$SubViewportContainer/SubViewport/Panel/Power.text = str(card_data['power']) 
	# Update visuals (mana cost, power, etc.)


func hilight_on():
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
	background = $SubViewportContainer/SubViewport/Panel/front/backgourd
	var sprites = [$Playable,$SubViewportContainer,$Summoning_sickness,$Back/Sprite2D]
	for sprite in sprites:
		var mat = sprite.material
		if mat and mat is ShaderMaterial:
			unique_material = mat.duplicate()
			sprite.material = unique_material

func _on_mouse_entered():
	if TurnManager.targeting:
		if movement.targeting_arrow:
			if not self in movement.targeting_arrow._potential_targets and can_be_attacked():
				movement.targeting_arrow._potential_targets.append(self.card_name)
	card_index = self.z_index
	if face_up and card_location != "mana":
		movement.highlighted = true
		TurnManager.highlighted = self
		self.z_index = card_index + 10
		movement.animate_scale(hover_scale)

func _on_mouse_exited():
	if not parts_highlighted:
		movement.highlighted = false
	
	self.z_index = card_index
	#movement.animate_scale(normal_scale)
	#highlightTween = create_tween()
	#highlightTween.tween_property(self, "scale", normal_scale, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func get_power():
	return card_data.get("power", 0)

func get_toughness():
	return card_data.get("toughness", 0)

func set_drag_visuals(is_dragging: bool):
	$SubViewportContainer.material.set_shader_parameter("grayscale_amount",  1.0 if is_dragging else 0.0)
	$SubViewportContainer.material.set_shader_parameter("alpha_override", 0.5 if is_dragging else 1.0)
	if can_be_payed() and is_dragging:
		controller.board.check_card(self)
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
	if $Summoning_sickness.material is ShaderMaterial:
			$Summoning_sickness.material.set_shader_parameter("ss", summoned_on_turn == TurnManager.turn)
	if  summoned_on_turn == TurnManager.turn:
		pass
		#has_summoning_sickness = true
	else:
		has_summoning_sickness = false
	
	#if (movement.highlighted and  card_location == "hand" ) or (movement.highlighted and  card_location == "field") :
		#self.z_index = card_index + 10
	#else:
		#self.z_index = card_index
		
	if dragging:
		global_position = get_global_mouse_position() - offset
	if face_up:
		if $Flip_animator.current_state == $Flip_animator.CardState.BACK_VISIBLE:
			$Flip_animator.flip_to_front()
			
		pass
	if player_controled  and TurnManager.current_phase == "main1":
		if can_be_payed() and card_location=="hand":
			if $Playable.material is ShaderMaterial:
				$Playable.material.set_shader_parameter("is_glowing", true)
		else:
			if $Playable.material is ShaderMaterial:
				$Playable.material.set_shader_parameter("is_glowing", false)
