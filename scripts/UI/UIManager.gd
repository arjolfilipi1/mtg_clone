extends Node
class_name UIManager
var selected:String =""
var done = false
var selected_card: CardState = null

func select_slot(valid_slots: Array[String]) -> String:
	TurnManager.selecting_slot = true
	TurnManager.highlight_valid_slots(valid_slots)

	var chosen := ""
	while TurnManager.selecting_slot and chosen == "":
		for slot in get_tree().get_nodes_in_group("slots"):
			if slot.is_hovered and Input.is_action_just_pressed("click_left"):
				chosen = slot.name
				break
		await TurnManager.game_manager.get_tree().process_frame

	TurnManager.clear_slot_highlights()
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
	print(options)
	var dialog = preload("res://scenes/ChoiceDialog.tscn").instantiate()
	dialog.created = true
	TurnManager.game_manager.get_tree().root.add_child(dialog)
	dialog.callv("show_confirm", [title]+options)
	
	dialog.choice_selected.connect(func(choice):
		self.selected = choice
		self.done= true
		dialog.queue_free()
		)
	while  not done:
		await TurnManager.game_manager.get_tree().process_frame
	done = false
	return selected

func show_stack(stack):
	print(stack)

func show_message(message):
	print(message)
func select_card_from(cards: Array, title: String = "Select a card") -> CardState:
	var preview_scene = preload("res://scenes/CardListViewer.tscn").instantiate()
	TurnManager.game_manager.get_tree().root.add_child(preview_scene)
	preview_scene.allow_selection = true
	preview_scene.show_cards(cards,title)  # existing method in your list


	
	var finished := false

	preview_scene.card_selected.connect(func(card):
		self.selected_card = card
		self.done = true
		print("responded with card "+card.card_name)
		
	)

	# Wait for player selection
	while not done:
		await TurnManager.game_manager.get_tree().process_frame
	preview_scene.queue_free()
	done = false
	return selected_card
