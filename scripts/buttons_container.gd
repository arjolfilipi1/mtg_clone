extends HBoxContainer
@onready var card:Card = $".."
func _ready() -> void:
	visible = false


func _on_mouse_entered() -> void:
	if visible:
		card.hilight_on()
		TurnManager.highlighted = card
		card.parts_highlighted = true
	pass # Replace with function body.
func _process(_delta: float) -> void:
	if not TurnManager.highlighted == card:
		visible = false
