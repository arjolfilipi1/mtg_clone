extends Control
class_name CardPreview

signal card_selected
var card_data:CardState
@onready var art:Sprite2D = $Panel/front/art
@onready var name_label = $Panel/Name
@onready var toughness = $Panel/Health
@onready var power = $Panel/Power
@onready var frame:ColorRect = $ColorRect

@onready var background:Sprite2D = $Panel/front/backgourd
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
		background = $Panel/front/backgourd
		var bg_unique_material := background.material.duplicate()
		background.material = bg_unique_material
		var color_list = []
		var max_str = ""
		var max_nr = 0
		for color in data.mana_cost.keys():
			if data.mana_cost[color] and color != "generic":
				color_list.append(color)
				if data.mana_cost[color] > max_nr:
					max_str = color
					max_nr = data.mana_cost[color]
		if max_str != "":
			background.texture = load("res://assets/card/%s.png" % max_str)
		var multi_color = len(color_list)
		if  multi_color:
			#if color_list[0] :
				#bg_unique_material.set_shader_parameter("mana_color1" ,_MANA_COLORS[color_list[0]])
				#bg_unique_material.set_shader_parameter("weight1" ,1.0/multi_color)
			if  multi_color > 1:
				bg_unique_material.set_shader_parameter("mana_color2" ,GameEnums._MANA_COLORS[ color_list[1]])
				bg_unique_material.set_shader_parameter("weight2" ,1.0/multi_color)
			if  multi_color > 2 :
				bg_unique_material.set_shader_parameter("mana_color3" ,GameEnums._MANA_COLORS[color_list[2]])
				bg_unique_material.set_shader_parameter("weight3" ,1.0/multi_color)
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
