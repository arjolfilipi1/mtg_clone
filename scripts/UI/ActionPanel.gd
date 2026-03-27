class_name ActionPanel
extends HBoxContainer

var current_card:Card = null

@onready var attack = $attack
@onready var activate = $activate
@onready var move = $move

signal action_selected(action_name, card)
func _ready() -> void:
	visible = false

func show_actions(card:Card, actions: Array):
	current_card = card
	z_index = card.z_index +1
	self.get_parent().remove_child(self)
	card.add_child(self)
	#global_position = card.global_position + Vector2( (self.size.x / len(actions)) * (len(actions) / 2 ),-100)
	var offset = (64 * len(actions)) + ( 30 * len(actions) -30 )
	global_position = card.global_position + Vector2( -offset,-100)
	activate.card = current_card
	attack.card = current_card
	move.card = current_card
	activate.visible = "activate" in actions
	attack.visible = "attack" in actions
	move.visible = "move" in actions
	visible = actions.size() > 0

func _on_action_pressed(action_name):
	emit_signal("action_selected", action_name, current_card)
