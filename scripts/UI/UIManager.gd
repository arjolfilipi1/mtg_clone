extends Node
class_name UIManager
var selected:String =""
var done = false
var ask_choice_done = false
var selected_card: CardState = null
var pending_target: CardState = null
var affected_b_slots: Array[Card]
var targeting_arrow
var attacker:Card
var debug : Label
var all_board_nodes:Array[Node] = []
const _TARGETING_SCENE = preload("res://scenes/TargetingArrow.tscn")
var selector:TargetSelector
var highlighted: Card
var player_mana_card_nr = 0
var enemy_mana_card_nr = 0
var selecting_slot: bool = false
var _effect_queue:Array = []
var _effect_playing := false
var hover_timer: SceneTreeTimer = null
var hovered_card: Card = null

func cancel_hover():
	if hover_timer:
		hover_timer.timeout.disconnect(_on_hover_timeout)
	if hovered_card:
		var unhighlight_tween = _clear_card_highlight(hovered_card)
		await unhighlight_tween.finished
		hovered_card = null

#hover logic
func on_card_hovered(card: Card):
	if card.moving:
		return
	if hover_timer:
		if hover_timer.is_connected("timeout",_on_hover_timeout):
			hover_timer.timeout.disconnect(_on_hover_timeout)
		hover_timer = null

	if highlighted == card:
		return  # already highlighted, nothing to do

	if highlighted and highlighted != card:
		_clear_card_highlight(highlighted)

	highlighted = card
	hovered_card = card
	_apply_card_highlight(card)

func on_card_unhovered(card: Card):
	hovered_card = null
	var delay = 1.0 if card.state.card_location == GameEnums.CardZone.FIELD else 0.3
	hover_timer = get_tree().create_timer(delay)
	hover_timer.timeout.connect(_on_hover_timeout.bind(card))

func _on_hover_timeout(card: Card):
	hover_timer = null
	if card.state.card_location == GameEnums.CardZone.MANA:
		return 
	if highlighted == card and hovered_card != card:
		_clear_card_highlight(card)
		highlighted = null

func _apply_card_highlight(card: Card):
	card.parts_highlighted = true
	card.z_index = card.card_index + 10
	var tween = card.create_tween()
	tween.tween_property(card, "scale", card.hover_scale, 0.2)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _clear_card_highlight(card: Card):
	card.parts_highlighted = false
	card.z_index = card.card_index
	var normal_scale = card.normal_scale
	if card.state.card_location == GameEnums.CardZone.FIELD:
		normal_scale = MovementManager.card_scale_field
	var tween = card.create_tween()
	tween.tween_property(card, "scale", normal_scale, 0.2)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	return tween
#effect
func queue_effect(card:Card)-> void:
	_effect_queue.append(card)
	if not _effect_playing:
		_play_next_effect()
func _play_next_effect()-> void:
	if _effect_queue.is_empty():
		_effect_playing = false
		return
	_effect_playing = true
	var card:Card =_effect_queue.pop_front()
	if not is_instance_valid(card) or not is_instance_valid(card.visual):
		_play_next_effect()
		return
	card.visual.effect_activation_finished.connect(_on_effect_finished,CONNECT_ONE_SHOT)
	card.visual.show_effect(null)
func _on_effect_finished() -> void:
	_play_next_effect()
func setup() -> void:
	targeting_arrow = _TARGETING_SCENE.instantiate()
	all_board_nodes = Game_Manager.tree.get_nodes_in_group("slots")
#attack
func request_attack():
	#card = action_panel.current_card
	var valid_targets: Array = Game_Manager.selected_card.state.can_attack(Game_Manager.gamestate)
	if valid_targets.is_empty():
		return

	get_viewport().set_input_as_handled()
	AttackManager.begin_attack(Game_Manager.selected_card, valid_targets)
func get_attack_targets(card:Card) -> Array:
	var targets = []
	
	var b = Game_Manager.gamestate.board_e
	var target_card_states = card.state.can_attack(Game_Manager.gamestate)
	for slot in b:
		if b[slot]:
			for c in b[slot]:
				if c in target_card_states:
					targets.append(c)
	return targets

func get_ranges(card:Card):
	var ranges = card.state.card_range
	var aplied : Array[String] = []
	for node in all_board_nodes:
		var origin = card.board_pos.name.split("-")
		for r in ranges :
			var parts = r.split(".")
			if node.name == str( int(origin[0]) - int(parts[0])) + "-" +str(int(origin[1]) - int(parts[1]) ):
				node.set_color(Vector4(0.8,0,0,0.75))
				node.og_color = Vector4(0.8,0,0,0.75)
				aplied.append(node.name)
			elif node.name not in aplied:
				node.og_color = (Vector4(0,0,0,0))
func cancel_attack():
	if selector and is_instance_valid(selector):
		selector.cancel()
		attacker.remove_child(selector)
		selector.queue_free()

func highlight_valid_slots(valid_slots: Array[String]):
	for node in all_board_nodes:
		if node.name in valid_slots:
			node.set_color(Vector4(0, 1, 0, 0.75)) # green for valid
		else:
			node.reset_higlight()
			
func start_attack_targeting(card:Card):
	attacker = card
	var targets = get_attack_targets(card)
	if targeting_arrow == null:
		targeting_arrow = _TARGETING_SCENE.instantiate()
		card.add_child(targeting_arrow)
	targeting_arrow.initiate_targeting()
	if not selector:
		selector = TargetSelector.new()
		add_child(selector)
	card.board_pos.color_range(false)
	get_ranges(card)
	selector.start_selection(targets)

	selector.completed.connect(func(chosen):
		if chosen.size() > 0:
			var target_card = chosen[0].card_node
			Game_Manager.request_confirmation(
				"Attack " + card.state.card_name + "?",
				func(): _execute_attack(card, target_card)
			)
	)
func _execute_attack(attacker: Card, defender: Card):
	# Let AttackManager handle the attack with visual movement
	AttackManager.execute_attack(attacker, defender)
func start_attack():
	attacker.movement.attack_card()
var highlighted_slots : Array[Area2D] = []

func clear_slot_highlights():
	for node in all_board_nodes:
		node.og_color = Vector4(0,0,0,0)
		node.reset_higlight()
#inputs
func select_slot(valid_slots: Array[String]) -> String:
	selecting_slot = true
	highlight_valid_slots(valid_slots)
	var chosen := ""
	while selecting_slot and chosen == "":
		for slot in get_tree().get_nodes_in_group("slots"):
			if slot.is_hovered and Input.is_action_just_pressed("click_left"):
				chosen = slot.name
				break
		await Game_Manager.get_tree().process_frame
	clear_slot_highlights()
	selecting_slot = false
	return chosen

func select_effect(effects: Array[Effect_class],card_name:String):
	var options = []
	for eff in effects:
		options.append(eff.spec)
	var choice = await ask_choice(options,"select effect for "+card_name)
	if choice == "":
		return null
	var index = options.find(choice)
	return effects[index]
	
func ask_choice(options:Array,title:String = "Choose")->String:
	var dialog = preload("res://scenes/ChoiceDialog.tscn").instantiate()
	dialog.created = true
	Game_Manager.get_tree().root.add_child(dialog)
	dialog.callv("show_confirm", [title]+options)
	
	dialog.choice_selected.connect(func(choice):
		self.selected = choice
		self.ask_choice_done= true
		dialog.queue_free()
		)
	while  not ask_choice_done:
		await Game_Manager.get_tree().process_frame
	ask_choice_done = false
	return selected

func show_stack(stack):
	#todo
	print(stack)

func show_message(message):
	#todo
	print(message)
	
func select_card_from(cards: Array, title: String = "Select a card") -> CardState:
	var preview_scene = preload("res://scenes/CardListViewer.tscn").instantiate()
	Game_Manager.get_tree().root.add_child(preview_scene)
	preview_scene.allow_selection = true
	preview_scene.show_cards(cards,title)  # existing method in your list


	preview_scene.card_selected.connect(func(card):
		self.selected_card = card
		self.done = true
		print("responded with card "+card.card_name)
		
	)

	# Wait for player selection
	while not done:
		await Game_Manager.get_tree().process_frame
	preview_scene.queue_free()
	done = false
	return selected_card
