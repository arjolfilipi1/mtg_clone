extends Node
class_name UIManager
var selected:String =""
var done = false
func ask_choice(options:Array[String],title:String = "Choose")->String:
	var dialog = preload("res://scenes/ChoiceDialog.tscn").instantiate()
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
func select_card_from(cards: Array[CardState], title: String = "Select a card") -> CardState:
	var preview_scene = preload("res://scenes/CardListViewer.tscn").instantiate()
	TurnManager.game_manager.get_tree().root.add_child(preview_scene)
	preview_scene.allow_selection = true
	preview_scene.show_cards(cards,title)  # existing method in your list


	var selected_card: CardState = null
	var finished := false

	preview_scene.card_selected.connect(func(card):
		selected_card = card
		finished = true
		preview_scene.queue_free()
	)

	# Wait for player selection
	while not finished:
		await TurnManager.game_manager.get_tree().process_frame
	return selected_card
