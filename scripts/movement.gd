extends Node2D
@onready var card:Card = $".."
var highlighted = false
var mana_tween
var highlightTween: Tween
var targeting_arrow
const _TARGETING_SCENE_FILE = "res://scenes/TargetingArrow.tscn"
const _TARGETING_SCENE = preload(_TARGETING_SCENE_FILE)
var affected: Array[Card]

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
						for card:Card in slot.card_list:
							card.visual.valid_target = true
							affected.append(card)

	card.board_pos.color_range(false)
func on_click(event):

	if event is InputEventMouseButton: 
		if event.button_index == MOUSE_BUTTON_LEFT :
			if card.player_controled and TurnManager.is_selecting_mana and  not card.controller.mana_selected and card.card_location == "hand" and event.pressed:  # New global flag
				move_to_mana_zone()

			if card.player_controled and TurnManager.current_phase == "main1"  and card.card_location == "hand":
				if event.pressed:
					TurnManager.dragging = card
					card.dragging = true
					card.offset = get_global_mouse_position() - card.global_position
					card.visual.set_drag_visuals(card.dragging)
					raise()  # Bring to front  # New global flag
				else:
					print("released card")
					check_and_return_to_hand()
			if TurnManager.targeting and TurnManager.current_phase == "attack"  and card.card_location == "field" and  event.pressed:
				print("attack?")
				pass
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed: 
			
			pass
	elif event is InputEventMouseMotion and card.dragging and card.card_location =="hand":
		card.global_position = get_global_mouse_position() - card.offset
		rotation = 0
	pass # Replace with function body.
func check_and_return_to_hand():
	card.controller.board.reset_higlight()
	TurnManager.reset_highlited()
	card.dragging = false
	position = Vector2(0,0)
	TurnManager.dragging = null
	card.visual.set_drag_visuals(card.dragging)
	card.check_drop_area()
	card.controller.player_hand.reset()
func animate_scale(target_scale: Vector2) -> void:
	if highlightTween:
		highlightTween.kill() # stop existing tweens
	highlightTween = create_tween()
	var track := highlightTween.parallel().tween_property(card, "scale", target_scale, 0.8).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	
	# Calculate how much the card will expand and adjust position
	

func play_card_to_board(area:Node,rot = 0):
	TurnManager.dragging = null
	TurnManager.reset_highlited()
	card.controller.creatures.append(card)
	card.controller.board.reset_higlight()
	card.face_up = true
	card.get_parent().remove_child(card)
	area.get_parent().add_child(card)
	var tween := get_tree().create_tween()
	tween.parallel().tween_property(card, "position", area.pos, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "scale", card.normal_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "rotation_degrees", rot, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	card.card_location = "field"
	#await tween.finished
	area.card_list.append(card)
	card.controller.pay_for_card(card)
	card.controller.player_hand.reset()
	TurnManager.priority = false if TurnManager.priority else true
	card.summoned_on_turn = TurnManager.turn
	pass

func move_to_mana_zone():
	highlighted = false
	card.face_up = true
	var mana_index = 0 
	var mana_offset = Vector2.ZERO
	card.controller.mana_selected = true
	if card.player_controled:
		TurnManager.player_mana_card_nr += 1
		mana_index = TurnManager.player_mana_card_nr
		#mana_offset = Vector2(30, 35)
	else:
		TurnManager.enemy_mana_card_nr += 1
		mana_index = TurnManager.enemy_mana_card_nr
		#mana_offset = Vector2(-50,-65)
	mana_offset = Vector2.ZERO
	
	var start_pos = card.global_position
	var target_pos = card.controller.player_mana_zone.global_position + Vector2(randf() * 10, 0) + mana_offset  # random offset so cards don't stack perfectly
	card.card_location = "mana"
	card.get_parent().remove_child(card)
	card.controller.player_mana_zone.add_child(card)
	card.z_index = mana_index
	card.global_position = start_pos
	mana_tween = get_tree().create_tween()
	
	mana_tween.parallel().tween_property(card, "global_position", target_pos, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if card.player_controled:
		mana_tween.parallel().tween_property(card, "rotation_degrees", 0.0, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	else:
		mana_tween.parallel().tween_property(card, "rotation_degrees", 180, 0.3).set_delay(0.5)
	
	mana_tween.tween_callback(Callable(self, "_after_mana_move"))

	
func _after_mana_move():
	lower()
	#if highlightTween:
		#highlightTween.kill()
	if card.player_controled:
		card.rotation = 0
	else:
		card.rotation_degrees = 180
	card.scale = Vector2(0.6,0.6)
	card.controller.player_hand.reset()
	
	#await get_tree().create_timer(0.3).timeout  # Small delay
	TurnManager.finish_mana_selection()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	targeting_arrow = _TARGETING_SCENE.instantiate()
	
	pass # Replace with function body.
func lower():
	if card.z_index >= 1000:
		card.z_index -= 1000
func raise():
	card.z_index += 1000
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if card.dragging:
		card.global_position = card.get_global_mouse_position() - card.offset
	match card.card_location:
		"hand": 
			card.normal_scale = Vector2(1.0,1.0)
		"mana": card.normal_scale = Vector2(0.6,0.6)
		"field": 
			card.normal_scale = Vector2(.5,.5)
			card.hover_scale = Vector2(.65,.65)
	pass
