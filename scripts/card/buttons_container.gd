extends HBoxContainer
@onready var card:Card = $".."
@onready var attack:TextureButton = $attack
@onready var activate:Button = $activate
var original_pos: Vector2
func _ready() -> void:
	visible = false
	original_pos = position
	
func _on_mouse_entered() -> void:
	if visible:
		card.hilight_on()
		TurnManager.highlighted = card
		card.parts_highlighted = true
	pass # Replace with function body.
func _process(_delta: float) -> void:
	if not TurnManager.highlighted == card:
		visible = false
	else:
		scale =  card.hover_scale /card.scale
		position.y = -100 * (card.hover_scale /card.scale).y
		
