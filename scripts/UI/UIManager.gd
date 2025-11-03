extends Node
class_name UIManager
var selected:String =""
var done = false

func select_effect(effects: Array[Effect_class],card_name:String):
	var options = []
	for eff in effects:
		options.append(eff.spec)
	var choice = await ask_choice(options,"select effect for "+card_name)
	if choice == "":
		return null
	var index = options.find(choice)
	return effects[index]
func ask_choice(options:Array[String],title:String = "Choose")->String:
	var dialog = preload("res://scenes/ChoiceDialog.tscn").instantiate()
	dialog.created = true
	TurnManager.game_manager.get_tree().root.add_child(dialog)
	dialog.show_confirm(title,options[0],options[1])
	
	
	dialog.choice_selected.connect(func(choice):
		selected = choice
		done= true
		dialog.queue_free()
		)
	while  not done:
		await TurnManager.game_manager.get_tree().process_frame
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


	var selected_card: CardState = null
	var finished := false

	preview_scene.card_selected.connect(func(card):
		selected_card = card
		finished = true
		print("responded with card "+card.card_name)
		preview_scene.queue_free()
	)

	# Wait for player selection
	while not finished:
		await TurnManager.game_manager.get_tree().process_frame
	return selected_card
