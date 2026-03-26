extends Node2D
#parent
@onready var card:Card = $".."
#if is highlighted
var highlighted = false
var mana_tween: Tween
var highlight_tween: Tween
#arrow for attack targeting
var targeting_arrow
const _TARGETING_SCENE = preload("res://scenes/TargetingArrow.tscn")
#stores cards that had the visuals changed (colored yellow to show that they are valid targets
# so that we can reset the visual
var affected: Array[Card]
var pending_target:Card

#attack visuals
func move_target():
	for pos in card.state.can_move(Game_Manager.gamestate):
		print(pos)
#attack visuals



func on_click(event):
	if event is InputEventMouseButton:
		var s: CardState = card.state

		if event.button_index == MOUSE_BUTTON_LEFT:
			# Mana selection
			if s.player_controled and TurnManager.is_selecting_mana and not TurnManager.waiting_for_input and not s.controller.mana_selected and s.card_location == GameEnums.CardZone.HAND and event.pressed:
				move_to_mana_zone()
			
			# Dragging from hand
			elif s.player_controled and TurnManager.current_phase == GameEnums.TurnEnum.MAIN and not TurnManager.waiting_for_input and s.card_location == GameEnums.CardZone.HAND:
				if event.pressed:
					TurnManager.dragging = card
					card.dragging = true
					card.offset = get_global_mouse_position() - card.global_position
					card.visual.set_drag_visuals(card.dragging)
					raise()
				else:
					print("released card")
					check_and_return_to_hand()
			
			# Attack targeting
			elif TurnManager.current_phase == GameEnums.TurnEnum.ATTACK \
			and card.visual.valid_target \
			and s.card_location == GameEnums.CardZone.FIELD and event.pressed:
				AttackManager.on_target_clicked(card)
				get_viewport().set_input_as_handled()
	
	elif event is InputEventMouseMotion and card.dragging and card.state.card_location == GameEnums.CardZone.HAND:
		card.global_position = get_global_mouse_position() - card.offset
		rotation = 0


#calls the attack animation

#check if the drop area can accept the card
func check_drop_area():
	if not card.state.can_be_payed(Game_Manager.gamestate,card.state.mana_cost):
		return false
	var mouse_pos = card.get_global_mouse_position()
	var space_state = card.get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position= mouse_pos
	parameters.collide_with_areas = true
	parameters.collide_with_bodies = false
	parameters.collision_mask = 0xFFFFFFFF
	var result = space_state.intersect_point(parameters)
	
	for hit in result:
		var collider = hit.collider
		if collider is Area2D and collider.is_in_group("player_slots"):
			
			print("Dropped on Area2D:", collider.name)
			play_card_to_board(collider,collider.scew_dict[collider.name])
			return
	card.dragging = false
	card.state.controller.player_hand.reset()

#dragging
func check_and_return_to_hand():
	card.state.controller.board.reset_higlight()
	UI_Manager.reset_highlited()
	card.dragging = false
	position = Vector2(0,0)
	TurnManager.dragging = null
	card.visual.set_drag_visuals(card.dragging)
	check_drop_area()
	card.state.controller.player_hand.reset()
	
#scales the card up when mouse enters, down when not in focus
func animate_scale(target_scale: Vector2) -> void:
	# Kill existing tween before creating new one
	if highlight_tween and highlight_tween.is_valid():
		highlight_tween.kill()
	highlight_tween = create_tween()
	highlight_tween.tween_property(card, "scale", target_scale, 0.8)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

#summon movement
func play_card_to_board(area: Node, rot = 0):
	card.board_pos = area
	TurnManager.dragging = null
	UI_Manager.reset_highlited()
	print("dropped " + card.state.card_name + " on area " + area.name)
	card.state.play_to_board(area.name, Game_Manager.gamestate)
	card.get_parent().remove_child(card)
	area.get_parent().add_child(card)
	
	var tween := create_tween()
	tween.parallel().tween_property(card, "position", area.pos, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "scale", card.normal_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "rotation_degrees", rot, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	area.card_list.append(card)
	card.state.controller.player_hand.reset()
	TurnManager.priority = false if TurnManager.priority else true

#moves the card to the mana pile
func move_to_mana_zone():
	highlighted = false
	card.state.face_up = true
	var mana_index = 0
	card.state.controller.mana_selected = true
	
	if card.state.player_controled:
		UI_Manager.player_mana_card_nr += 1
		mana_index = UI_Manager.player_mana_card_nr
	else:
		UI_Manager.enemy_mana_card_nr += 1
		mana_index = UI_Manager.enemy_mana_card_nr
	
	var start_pos = card.global_position
	card.state.to_mana(Game_Manager.gamestate)
	
	card.get_parent().remove_child(card)
	card.state.controller.player_mana_zone.add_child(card)
	card.z_index = mana_index
	card.global_position = start_pos
	
	# Clean up existing mana tween
	if mana_tween and mana_tween.is_valid():
		mana_tween.kill()
	
	mana_tween = create_tween()
	mana_tween.parallel().tween_property(card, "position", Vector2(-40.0, -50.0), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	if card.state.player_controled:
		mana_tween.parallel().tween_property(card, "rotation_degrees", 0.0, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	else:
		mana_tween.parallel().tween_property(card, "rotation_degrees", 180, 0.3).set_delay(0.5)
	
	mana_tween.tween_callback(_after_mana_move)

	
func _after_mana_move():
	lower()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if card.state.player_controled:
		card.rotation = 0
	else:
		card.rotation_degrees = 180
	card.scale = Vector2(0.6, 0.6)
	card.state.controller.player_hand.reset()
	
	# Clean up mana tween after use
	if mana_tween and mana_tween.is_valid():
		mana_tween = null
	
	TurnManager.finish_mana_selection()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	targeting_arrow = _TARGETING_SCENE.instantiate()
	
func _exit_tree():
	"""Clean up all tweens when node is removed"""
	_cleanup_tweens()

func _cleanup_tweens():
	"""Kill and nullify all tweens"""
	if mana_tween and mana_tween.is_valid():
		mana_tween.kill()
		mana_tween = null
	
	if highlight_tween and highlight_tween.is_valid():
		highlight_tween.kill()
		highlight_tween = null
 
func lower():
	if card.z_index >= 1000:
		card.z_index -= 1000
func raise():
	card.z_index += 1000


func _process(_delta: float) -> void:
	if card.dragging:
		card.global_position = card.get_global_mouse_position() - card.offset
	match card.state.card_location:
		GameEnums.CardZone.HAND: 
			card.normal_scale = Vector2(1.0,1.0)
		GameEnums.CardZone.MANA: card.normal_scale = Vector2(0.6,0.6)
		GameEnums.CardZone.FIELD: 
			card.normal_scale = Vector2(.5,.5)
			card.hover_scale = Vector2(.65,.65)
