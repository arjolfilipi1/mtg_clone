extends Control
class_name CardListViewer

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var grid: VBoxContainer = $VBoxContainer/ScrollContainer/CardGrid
@onready var panel: =$ColorRect
@onready var vb: =$VBoxContainer
@export var card_preview_scene: PackedScene= preload("res://scenes/CardPreview.tscn")

var card_states: Array[CardState] = []

var selected_card: CardState = null
@export var allow_selection: bool = false
signal card_selected(card_state: CardState)
signal card_action(action: String, card_state: CardState)

func _ready():
	pass
func show_cards(effects: Array):
	card_states = []
	for effect_ctx in effects:
		print(effect_ctx)
		card_states.append(effect_ctx.source)


	# Clear old previews
	for c in grid.get_children():
		c.queue_free()

	# Add new previews
	for cs in card_states:
		var preview := card_preview_scene.instantiate()
		preview.setup_from_card_state(cs)
		grid.add_child(preview)
		preview.card_selected.connect(_on_card_clicked.bind(cs))
	if allow_selection:
		var center = get_viewport_rect().size / 2
		panel.global_position = center
		vb.global_position = center
	show()
	move_to_front()

func _on_card_clicked(card_state: CardState):
	selected_card = card_state
	card_selected.emit(card_state)
	# highlight or indicate selection
	for p in grid.get_children():
		p.set_selected(p.card_data == card_state)
