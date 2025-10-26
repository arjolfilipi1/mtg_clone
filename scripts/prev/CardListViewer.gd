extends Control
class_name CardListViewer

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var grid: GridContainer = $VBoxContainer/ScrollContainer/CardGrid
@onready var button_close: Button = $VBoxContainer/ButtonBar/Btn_Close
@onready var button_activate: Button = $VBoxContainer/ButtonBar/Btn_Activate


@export var card_preview_scene: PackedScene= preload("res://scenes/CardPreview.tscn")

var card_states: Array[CardState] = []

var selected_card: CardState = null
signal card_selected(card_state: CardState)
signal card_action(action: String, card_state: CardState)

func _ready():
	button_close.pressed.connect(_on_close_pressed)
	button_activate.pressed.connect(_on_activate_pressed)
	button_activate.disabled = true
	hide()  # hidden by default

func show_cards(cards: Array[CardState], title: String = "Cards in Graveyard"):
	card_states = cards
	title_label.text = title

	# Clear old previews
	for c in grid.get_children():
		c.queue_free()

	# Add new previews
	for cs in cards:
		var preview := card_preview_scene.instantiate()
		preview.setup_from_card_state(cs)
		grid.add_child(preview)
		preview.card_selected.connect(_on_card_clicked.bind(cs))

	show()
	move_to_front()

func _on_card_clicked(card_state: CardState):
	selected_card = card_state
	card_selected.emit(card_state)
	# highlight or indicate selection
	for effect in selected_card.effects:
		print(effect.trigger_spec)
		if effect.trigger_spec == "selected_on_mana" and title_label.text == "Mana":
			button_activate.disabled = false
	for p in grid.get_children():
		p.set_selected(p.card_data["card_name"] == card_state.card_name)

func _on_close_pressed():
	hide()

func _on_activate_pressed():
	if selected_card:
		var res = []
		for effect in selected_card.effects:
			print(effect.trigger_spec)
			if effect.trigger_spec == "selected_on_mana" and title_label.text == "Mana":
				res.append(effect)
				if len(res) == 1:
					selected_card.apply_effect(res[0])
		card_action.emit("activate", selected_card)
		hide()
