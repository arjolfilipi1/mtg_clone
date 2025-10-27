extends Node2D
#parent
@onready var card:Card = $".."
#if is highlighted
var highlighted = false
var mana_tween
var highlightTween: Tween
#arrow for attack targeting
var targeting_arrow
const _TARGETING_SCENE_FILE = "res://scenes/TargetingArrow.tscn"
const _TARGETING_SCENE = preload(_TARGETING_SCENE_FILE)
#stores cards that had the visuals changed (colored yellow to show that they are valid targets
# so that we can reset the visual
var affected: Array[Card]
var pending_target:Card

#attack visuals
func attack_target():
	if card.is_ancestor_of(targeting_arrow):
		pass
	else:
		card.add_child(targeting_arrow)
	targeting_arrow.initiate_targeting()
	var sn:String = TurnManager.targeting.board_pos.name
	var origin = sn.split("-")
	for player:Player in TurnManager.players:
		for slot in  (player.board.board_slots):
			if slot.card_list:
				var ranges :Array = TurnManager.targeting.card_data['range']
				for r in ranges :
					var parts = r.split(".")
					if slot.name == str( int(origin[0]) - int(parts[0])) + "-" +str(int(origin[1]) - int(parts[1]) ):
						for c:Card in slot.card_list:
							c.visual.valid_target = true
							affected.append(c)

	card.board_pos.color_range(false)


func on_click(event):

	if event is InputEventMouseButton: 
		var s:CardState = card.state
		if event.button_index == MOUSE_BUTTON_LEFT :
			#card.pressed.emit()
			if s.player_controled and TurnManager.is_selecting_mana and not TurnManager.waiting_for_input and  not s.controller.mana_selected and s.card_location == CardState.le.hand and event.pressed:  # New global flag
				move_to_mana_zone()

			if s.player_controled and TurnManager.current_phase == TurnManager.TurnEnum.MAIN and not TurnManager.waiting_for_input  and s.card_location == CardState.le.hand:
				if event.pressed:
					TurnManager.dragging = card
					card.dragging = true
					card.offset = get_global_mouse_position() - card.global_position
					card.visual.set_drag_visuals(card.dragging)
					raise()  # Bring to front  # New global flag
				else:
					print("released card")
					check_and_return_to_hand()
			if TurnManager.targeting and card.visual.valid_target and TurnManager.current_phase == TurnManager.TurnEnum.ATTACK  and s.card_location == CardState.le.field and  event.pressed:
				TurnManager.targeting.movement.pending_target = card
				TurnManager.game_manager.request_confirmation("Attack "+card.state.card_name+"?",attack_card)
				pass
		
	elif event is InputEventMouseMotion and card.dragging and card.state.card_location ==CardState.le.hand:
		card.global_position = get_global_mouse_position() - card.offset
		rotation = 0
	pass
#calls the attack animation
func attack_card():
	
	card.visual.attack.start_slam_attack(TurnManager.targeting,card)
#check if the drop area can accept the card
func check_drop_area():
	var mouse_pos = card.get_global_mouse_position()
	var space_state = card.get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	if not card.state.can_be_payed(TurnManager.game_manager.gamestate,card.state.mana_cost):
		return false
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
	TurnManager.reset_highlited()
	card.dragging = false
	position = Vector2(0,0)
	TurnManager.dragging = null
	card.visual.set_drag_visuals(card.dragging)
	check_drop_area()
	card.state.controller.player_hand.reset()
	
#scales the card up when mouse enters, down when not in focus
func animate_scale(target_scale: Vector2) -> void:
	if highlightTween :
		if is_instance_valid(highlightTween) :
			highlightTween.kill() # stop existing tweens
	highlightTween = get_tree().create_tween()
	var _track := highlightTween.parallel().tween_property(card, "scale", target_scale, 0.8).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	

	
#summon movement
func play_card_to_board(area:Node,rot = 0):
	card.board_pos =  area
	TurnManager.dragging = null
	TurnManager.reset_highlited()
	print("dropped "+ card.state.card_name+ " on area "+ area.name)
	card.state.play_to_board(area.name,TurnManager.game_manager.gamestate,card)
	card.get_parent().remove_child(card)
	area.get_parent().add_child(card)
	var tween := get_tree().create_tween()
	tween.parallel().tween_property(card, "position", area.pos, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "scale", card.normal_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "rotation_degrees", rot, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	#await tween.finished
	area.card_list.append(card)
	card.state.controller.player_hand.reset()
	TurnManager.priority = false if TurnManager.priority else true
	pass

#moves the card to the mana pile
func move_to_mana_zone():
	highlighted = false
	card.state.face_up = true
	var mana_index = 0 
	var _mana_offset = Vector2.ZERO
	card.state.controller.mana_selected = true
	if card.state.player_controled:
		TurnManager.player_mana_card_nr += 1
		mana_index = TurnManager.player_mana_card_nr
		#mana_offset = Vector2(30, 35)
	else:
		TurnManager.enemy_mana_card_nr += 1
		mana_index = TurnManager.enemy_mana_card_nr
		#mana_offset = Vector2(-50,-65)
	_mana_offset = Vector2.ZERO
	
	var start_pos = card.global_position
	#var target_pos = card.state.controller.player_mana_zone.global_position + Vector2(randf() * 10, 0) + mana_offset  # random offset so cards don't stack perfectly
	card.state.to_mana(TurnManager.game_manager.gamestate)
	
	card.get_parent().remove_child(card)
	card.state.controller.player_mana_zone.add_child(card)
	card.z_index = mana_index
	card.global_position = start_pos
	mana_tween = get_tree().create_tween()
	
	mana_tween.parallel().tween_property(card, "position", Vector2(-40.0,-50.0), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if card.state.player_controled:
		mana_tween.parallel().tween_property(card, "rotation_degrees", 0.0, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	else:
		mana_tween.parallel().tween_property(card, "rotation_degrees", 180, 0.3).set_delay(0.5)
	
	mana_tween.tween_callback(Callable(self, "_after_mana_move"))

	
func _after_mana_move():
	lower()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	#if highlightTween:
		#highlightTween.kill()
	if card.state.player_controled:
		card.rotation = 0
	else:
		card.rotation_degrees = 180
	card.scale = Vector2(0.6,0.6)
	card.state.controller.player_hand.reset()
	
	#await get_tree().create_timer(0.3).timeout  # Small delay
	TurnManager.finish_mana_selection()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	targeting_arrow = _TARGETING_SCENE.instantiate()
	
	pass 
func lower():
	if card.z_index >= 1000:
		card.z_index -= 1000
func raise():
	card.z_index += 1000


func _process(_delta: float) -> void:
	if card.dragging:
		card.global_position = card.get_global_mouse_position() - card.offset
	match card.state.card_location:
		CardState.le.hand: 
			card.normal_scale = Vector2(1.0,1.0)
		CardState.le.mana: card.normal_scale = Vector2(0.6,0.6)
		CardState.le.field: 
			card.normal_scale = Vector2(.5,.5)
			card.hover_scale = Vector2(.65,.65)
	pass
