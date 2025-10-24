extends Control
class_name CardListViewer

@onready var grid = $VBoxContainer/CardGrid
@onready var title_label = $VBoxContainer/Title

@export var card_preview_scene: PackedScene= preload("res://scenes/CardPreview.tscn")

func show_cards(cards: Array[CardState], title: String = "Cards"):
	title_label.text = title
	for c in grid.get_children():
		c.queue_free()

	for card_data in cards:
		var preview = card_preview_scene.instantiate()
		preview.setup(card_data)
		grid.add_child(preview)

	show()
