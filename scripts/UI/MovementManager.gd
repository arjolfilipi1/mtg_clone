extends Node
var targeting_arrow
const _TARGETING_SCENE = preload("res://scenes/TargetingArrow.tscn")
var mana_tween: Tween
# Movement types
enum MoveType {
	DRAW,
	PLAY_TO_BOARD,
	MOVE_TO_MANA,
	MOVE_TO_GRAVE,
	SLOT_TO_SLOT,
	RETURN_TO_HAND,
	CARD_DRAG
}
# Movement configuration
var movement_duration: float = 0.3
var card_scale_normal: Vector2 = Vector2(1.0, 1.0)
var card_scale_hover: Vector2 = Vector2(1.2, 1.2)
var card_scale_mana: Vector2 = Vector2(0.6, 0.6)
var card_scale_field: Vector2 = Vector2(0.5, 0.5)
# Active movements tracking
var active_movements: Dictionary = {}  # card -> {tween, type, callback}
var pending_movements: Array = []      # Queue for movements
# Signals
signal movement_started(card: Card, move_type: MoveType)
signal movement_completed(card: Card, move_type: MoveType)
signal movement_cancelled(card: Card, move_type: MoveType)
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

# ============ Public API ============
func move_card_to_board(card: Card, target_slot: Area2D, rotation: float = 0.0, 
						callback: Callable = Callable()) -> Tween:
	"""Move a card from hand to board slot"""
	if not _validate_movement(card):
		return null
	
	var move_data = {
		"type": MoveType.PLAY_TO_BOARD,
		"card": card,
		"target_pos": target_slot.pos,
		"target_scale": card_scale_field,
		"target_rotation": rotation,
		"callback": callback,
		"extra": {"slot": target_slot}
	}
	
	return _execute_movement(move_data)

func move_card_to_mana(card: Card, is_player: bool, mana_zone_index: int,
					   callback: Callable = Callable()) -> Tween:
	"""Move a card from hand to mana zone"""
	if not _validate_movement(card):
		return null
	
	# Calculate target position in mana zone
	var mana_zone = card.state.controller.player_mana_zone
	var target_pos = Vector2(-40.0, -50.0)  # Relative position
	
	var move_data = {
		"type": MoveType.MOVE_TO_MANA,
		"card": card,
		"target_pos": target_pos,
		"target_scale": card_scale_mana,
		"target_rotation": 0.0 if is_player else 180.0,
		"callback": callback,
		"extra": {"is_player": is_player, "mana_zone": mana_zone, "index": mana_zone_index}
	}
	
	return _execute_movement(move_data)

func move_card_to_grave(card: Card, from_pos: Vector2, callback: Callable = Callable()) -> Tween:
	"""Move a card to graveyard with burn effect"""
	if not _validate_movement(card):
		return null
	
	# Calculate burn effect path
	var burn_offset = Vector2(randf_range(-50, 50), randf_range(-30, 30))
	
	var move_data = {
		"type": MoveType.MOVE_TO_GRAVE,
		"card": card,
		"target_pos": from_pos + burn_offset,
		"target_scale": Vector2(0.3, 0.3),
		"target_rotation": randf_range(-45, 45),
		"callback": callback,
		"extra": {"burn": true, "from_pos": from_pos}
	}
	
	return _execute_movement(move_data)

func move_card_between_slots(card: Card, from_slot: Area2D, to_slot: Area2D,
							 callback: Callable = Callable()) -> Tween:
	"""Move a card from one board slot to another"""
	if not _validate_movement(card):
		return null
	
	var move_data = {
		"type": MoveType.SLOT_TO_SLOT,
		"card": card,
		"target_pos": to_slot.pos,
		"target_scale": card_scale_field,
		"target_rotation": to_slot.scew_dict.get(to_slot.name, 0),
		"callback": callback,
		"extra": {"from_slot": from_slot, "to_slot": to_slot}
	}
	
	return _execute_movement(move_data)

func animate_card_drag(card: Card, mouse_position: Vector2, offset: Vector2) -> void:
	"""Handle card dragging (real-time position updates)"""
	if not card or not is_instance_valid(card):
		return
	
	# Update position directly without tween
	card.global_position = mouse_position - offset
	card.rotation = 0
	
	# Update visual feedback
	if card.visual:
		var can_play = card.state.can_be_payed(Game_Manager.gamestate, card.state.mana_cost)
		var alpha = 0.5 if can_play else 0.7
		card.visual.set_drag_visuals(true, alpha)
		
		# Highlight valid slots while dragging
		if can_play:
			card.state.controller.board.check_card(card, Game_Manager.gamestate)

func end_card_drag(card: Card, drop_position: Vector2) -> void:
	"""Handle card drop after dragging"""
	if not card or not is_instance_valid(card):
		return
	
	card.dragging = false
	card.visual.set_drag_visuals(false)
	
	# Find valid drop target
	var target_slot = _find_drop_target(card, drop_position)
	
	if target_slot and target_slot.accepts_card(card, Game_Manager.gamestate):
		# Successfully played
		move_card_to_board(card, target_slot, target_slot.scew_dict.get(target_slot.name, 0))
		card.state.play_to_board(target_slot.name, Game_Manager.gamestate)
		target_slot.card_list.append(card)
	else:
		# Return to hand
		_return_to_hand(card)
	
	# Clean up
	card.state.controller.board.reset_higlight()
	UI_Manager.clear_slot_highlights()
	TurnManager.dragging = null

func cancel_movement(card: Card) -> void:
	"""Cancel any ongoing movement for a card"""
	if card in active_movements:
		var movement = active_movements[card]
		if movement.tween and movement.tween.is_valid():
			movement.tween.kill()
		active_movements.erase(card)
		movement_cancelled.emit(card, movement.type)

func is_card_moving(card: Card) -> bool:
	"""Check if a card is currently moving"""
	return card in active_movements

# ============ Private Methods ============

func _validate_movement(card: Card) -> bool:
	"""Validate if movement can start"""
	if not card or not is_instance_valid(card):
		return false
	
	# Cancel existing movement if any
	if is_card_moving(card):
		cancel_movement(card)
	
	return true

func _execute_movement(move_data: Dictionary) -> Tween:
	"""Execute a movement with tween"""
	var card = move_data.card
	var move_type = move_data.type
	
	# Store original state
	var original_parent = card.get_parent()
	var original_pos = card.position
	var original_scale = card.scale
	var original_rotation = card.rotation
	
	# Create tween
	var tween = card.create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	
	# Position animation
	tween.tween_property(card, "position", move_data.target_pos, movement_duration)
	tween.tween_property(card, "scale", move_data.target_scale, movement_duration)
	
	if move_data.has("target_rotation"):
		tween.tween_property(card, "rotation_degrees", move_data.target_rotation, movement_duration)
	
	# Store movement data
	active_movements[card] = {
		"tween": tween,
		"type": move_type,
		"original_parent": original_parent,
		"original_pos": original_pos,
		"original_scale": original_scale,
		"original_rotation": original_rotation,
		"callback": move_data.callback,
		"extra": move_data.get("extra", {})
	}
	
	movement_started.emit(card, move_type)
	
	# Connect completion signal
	tween.finished.connect(_on_movement_finished.bind(card, move_data))
	
	# Handle reparenting if needed
	if move_type == MoveType.PLAY_TO_BOARD:
		_handle_board_reparenting(card, move_data.extra.slot)
	elif move_type == MoveType.MOVE_TO_MANA:
		_handle_mana_reparenting(card, move_data.extra.mana_zone)
	
	return tween

func _on_movement_finished(card: Card, move_data: Dictionary) -> void:
	"""Called when movement tween completes"""
	if not card or not is_instance_valid(card):
		return
	
	var move_type = move_data.type
	
	# Apply post-movement logic
	match move_type:
		MoveType.PLAY_TO_BOARD:
			_post_play_to_board(card, move_data)
		MoveType.MOVE_TO_MANA:
			_post_move_to_mana(card, move_data)
		MoveType.MOVE_TO_GRAVE:
			_post_move_to_grave(card, move_data)
		MoveType.SLOT_TO_SLOT:
			_post_slot_to_slot(card, move_data)
	
	# Call callback if provided
	if move_data.callback != Callable():
		move_data.callback.call(card)
	
	# Clean up tracking
	active_movements.erase(card)
	movement_completed.emit(card, move_type)

func _handle_board_reparenting(card: Card, target_slot: Area2D) -> void:
	"""Reparent card to board during movement"""
	# Don't reparent immediately, wait for movement to finish
	# Store that we need to reparent after movement
	card._pending_reparent = {"target": target_slot.get_parent(), "slot": target_slot}

func _handle_mana_reparenting(card: Card, mana_zone: Node) -> void:
	"""Reparent card to mana zone during movement"""
	card._pending_reparent = {"target": mana_zone}

func _post_play_to_board(card: Card, move_data: Dictionary) -> void:
	"""Handle post-movement logic for playing to board"""
	if card.has_meta("pending_reparent"):
		var reparent_data = card.get_meta("pending_reparent")
		card.get_parent().remove_child(card)
		reparent_data.target.add_child(card)
		card.remove_meta("pending_reparent")
		
		# Update slot reference
		if reparent_data.has("slot"):
			card.board_pos = reparent_data.slot
	
	card.state.card_location = GameEnums.CardZone.FIELD
	card.mouse_filter = Control.MOUSE_FILTER_PASS

func _post_move_to_mana(card: Card, move_data: Dictionary) -> void:
	"""Handle post-movement logic for moving to mana"""
	var extra = move_data.extra
	
	if card.has_meta("pending_reparent"):
		var reparent_data = card.get_meta("pending_reparent")
		card.get_parent().remove_child(card)
		reparent_data.target.add_child(card)
		card.remove_meta("pending_reparent")
	
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.z_index = extra.index
	
	# Spawn mana orbs based on card's mana creation
	for mana_type in card.state.mana_creation:
		var orb = extra.mana_zone.spawn_mana_orb(mana_type, Vector2(100, 125), extra.mana_zone)
		orb.mana_type = mana_type
		extra.mana_zone.player_orbs[mana_type].append(orb)

func _post_move_to_grave(card: Card, move_data: Dictionary) -> void:
	"""Handle post-movement logic for moving to graveyard"""
	card.queue_free()

func _post_slot_to_slot(card: Card, move_data: Dictionary) -> void:
	"""Handle post-movement logic for slot to slot movement"""
	var extra = move_data.extra
	
	# Update slot references
	if extra.from_slot:
		extra.from_slot.card_list.erase(card)
	if extra.to_slot:
		extra.to_slot.card_list.append(card)
	
	card.board_pos = extra.to_slot

func _return_to_hand(card: Card) -> void:
	"""Return a card to hand after failed drag"""
	var tween = card.create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "position", Vector2.ZERO, 0.2)
	tween.tween_property(card, "scale", Vector2.ONE, 0.2)
	tween.tween_property(card, "rotation", 0.0, 0.2)
	
	await tween.finished
	card.state.controller.player_hand.reset()

func _find_drop_target(card: Card, mouse_pos: Vector2) -> Area2D:
	"""Find which slot the card is being dropped on"""
	var space_state = card.get_world_2d().direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.position = mouse_pos
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = 0xFFFFFFFF
	
	var results = space_state.intersect_point(params)
	
	for hit in results:
		var collider = hit.collider
		if collider is Area2D and collider.is_in_group("player_slots"):
			return collider
	
	return null
