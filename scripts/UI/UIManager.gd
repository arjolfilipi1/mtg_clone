extends Node
class_name UIManager

func show_stack(stack):
	print(stack)

func show_message(message):
	print(message)
func select_card_from(cards: Array[CardState], title: String = "Select a card") -> CardState:
	var preview_scene = preload("res://scenes/CardPreview.tscn").instantiate()
	get_tree().root.add_child(preview_scene)
	preview_scene.allow_selection = true
	preview_scene.set_cards(cards)  # existing method in your list
	preview_scene.set_title(title)

	var selected_card: CardState = null
	var finished := false

	preview_scene.card_selected.connect(func(card):
		selected_card = card
		finished = true
		preview_scene.queue_free()
	)

	# Wait for player selection
	while not finished:
		await get_tree().process_frame
	return selected_card
