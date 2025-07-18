extends HBoxContainer
@onready var card:Control = $".."
func _ready() -> void:
	visible = false


func _on_mouse_entered() -> void:
	if visible:
		card.hilight_on()
	pass # Replace with function body.
