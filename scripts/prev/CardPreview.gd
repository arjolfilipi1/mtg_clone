extends Control
class_name CardPreview

@onready var art = $Panel/front/art
@onready var name_label = $Panel/Name
@onready var toughness = $Panel/Health
@onready var power = $Panel/Power

var card_data: Dictionary

func setup(data: CardState):
	# data is a plain card dictionary (from your database or card_state.card_data)
	name_label.text = data.card_name
	toughness.text = data.toughness
	power.text = data.power
	
	var art_path = data.card_data.image
	if art_path != "":
		art.texture = load(art_path)
