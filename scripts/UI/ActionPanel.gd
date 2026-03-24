class_name ActionPanel
extends HBoxContainer
@onready var attack = $attack
@onready var activate = $activate
@onready var move = $move

signal action_selected(action_name, card)

var current_card:Card = null
func _ready() -> void:
	visible = false
func show_actions(card:Card, actions: Array):
	current_card = card
	z_index = card.z_index +1
	global_position = card.global_position + Vector2(0,-100)
	if "activate" in actions:
		activate.card = current_card
		activate.visible = true
	if "attack" in actions:
		attack.card = current_card
		attack.visible = true
	if "move" in actions:
		move.card = current_card
		move.visible = true
	visible = actions.size() > 0

func _on_action_pressed(action_name):
	emit_signal("action_selected", action_name, current_card)
