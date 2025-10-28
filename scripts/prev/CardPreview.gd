extends Control
class_name CardPreview

signal card_selected
var card_data:CardState
@onready var art:Sprite2D = $Panel/front/art
@onready var name_label = $Panel/Name
@onready var toughness = $Panel/Health
@onready var power = $Panel/Power
@onready var frame:ColorRect = $ColorRect
var selected: bool = false
func _ready() -> void:
	frame.visible = false
	$ColorRect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Panel/ManaCostContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Panel/CenterContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
func scale_sprite_preserving_center(_art: Sprite2D, frame_size: Vector2 = Vector2(160, 140), fill: bool = false) -> void:
	
	var sprite = Sprite2D.new()
	sprite.texture = _art.texture
	if sprite.texture == null:
		return

	var tex_size = sprite.texture.get_size()
	print("tex_size",tex_size)
	var scale_factor: float

	if fill:
		scale_factor = max(frame_size.x / tex_size.x, frame_size.y / tex_size.y)
	else:
		scale_factor = min(frame_size.x / tex_size.x, frame_size.y / tex_size.y)

	art.scale = Vector2.ONE * scale_factor
	#sprite.offset = -tex_size / 2  # Center the texture visually
	
	
func setup_from_card_state(data: CardState):
	card_data = data
	name_label = $Panel/Name
	art = $Panel/front/art
	toughness = $Panel/Health
	power = $Panel/Power
	
	if data:
		# data is a plain card dictionary (from your database or card_state.card_data)
		name_label.text = str(data.card_name)
		toughness.text = str(data.toughness)
		power.text = str(data.power)
		
		var art_path = "res://assets/art/"+data.card_data.image
		if art_path != "":
			art.texture = load(art_path)
			scale_sprite_preserving_center(art)
func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_selected.emit()

func set_selected(is_selected: bool):
	selected = is_selected
	frame.visible = is_selected
	frame.color =  Color(0.0,0.8,0,0.25)


func _on_mouse_entered() -> void:
	if selected == false:
		frame.visible = true
		frame.color =  Color(0.8,0.8,0,0.25)


func _on_mouse_exited() -> void:
	if selected == false:
		frame.visible = false
