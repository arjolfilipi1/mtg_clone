extends Node
class_name UIManager
var selected:String =""
var done = false
var selected_card: CardState = null
var pending_target: CardState = null
var affected_b_slots: Array[Card]
var targeting_arrow
var attacker:Card
var all_board_nodes:Array[Node] = []
const _TARGETING_SCENE = preload("res://scenes/TargetingArrow.tscn")
var selector:TargetSelector

func setup() -> void:
	targeting_arrow = _TARGETING_SCENE.instantiate()
	all_board_nodes = Game_Manager.tree.get_nodes_in_group("slots")
	
func get_attack_targets(card) -> Array:
	var targets = []
	
	var origin = card.board_pos.name  # ← FIX THIS (see below)
	var b = Game_Manager.gamestate.board_e
	for slot in b:
		if b[slot]:
			for c in b[slot]:
				targets.append(c)

	return targets

func get_ranges(card:Card):
	var ranges = card.state.card_range
	var aplied : Array[String] = []
	for node in all_board_nodes:
		var origin = card.board_pos.name.split("-")
		print(origin)
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

	selector.completed.connect(func(selected):
		if selected.size() > 0:
			#Game_Manager.request_attack(card, selected[0])
			card.movement.pending_target = selected[0].card_node
			Game_Manager.request_confirmation("Attack "+card.state.card_name+"?", card.movement.attack_card)
	)
func start_attack():
	attacker.movement.attack_card()
var highlighted_slots : Array[Area2D] = []
func reset_highlited():
	for node:Area2D in highlighted_slots:
		node.og_color = Vector4(0,0,0,0)
func clear_slot_highlights():
	for node in all_board_nodes:
		node.reset_higlight()
func select_slot(valid_slots: Array[String]) -> String:
	TurnManager.selecting_slot = true
	highlight_valid_slots(valid_slots)

	var chosen := ""
	while TurnManager.selecting_slot and chosen == "":
		for slot in get_tree().get_nodes_in_group("slots"):
			if slot.is_hovered and Input.is_action_just_pressed("click_left"):
				chosen = slot.name
				break
		await Game_Manager.get_tree().process_frame

	clear_slot_highlights()
	TurnManager.selecting_slot = false
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
		self.done= true
		dialog.queue_free()
		)
	while  not done:
		await Game_Manager.get_tree().process_frame
	done = false
	return selected

func show_stack(stack):
	print(stack)

func show_message(message):
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
