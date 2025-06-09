extends Node
@onready var card:Control = $".."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func set_background_color():
	#ShaderMaterial
	const _MANA_COLORS = {
	"generic": Color(0.7, 0.7, 0.7),
	"white": Color(1, 1, 1),
	"black": Color(0.4, 0.4, 0.4),
	"green": Color(0.1, 0.8, 0.1),
	"blue": Color(0.1, 0.6, 1),
	"red": Color(1, 0.2, 0.2),
	"earth": Color(0.6, 0.4, 0.2)
}
	var card_sprite: Sprite2D = $"../SubViewportContainer/SubViewport/Panel/front/backgourd"

# Duplicate the material (shallow copy still shares the shader, which is fine)
	var bg_unique_material := card_sprite.material.duplicate()
	card_sprite.material = bg_unique_material
	var color_list = []
	for color in card.mana_cost.keys():
		if card.mana_cost[color] and color != "generic":
			color_list.append(color)
	var multi_color = len(color_list)
	if color_list[0] :
		bg_unique_material.set_shader_parameter("mana_color1" ,_MANA_COLORS[color_list[0]])
		bg_unique_material.set_shader_parameter("weight1" ,1.0/multi_color)
	if  multi_color > 1:
		bg_unique_material.set_shader_parameter("mana_color1" ,_MANA_COLORS[color_list[1]])
		bg_unique_material.set_shader_parameter("weight1" ,1.0/multi_color)
	if  multi_color == 3 :
		bg_unique_material.set_shader_parameter("mana_color1" ,_MANA_COLORS[color_list[2]])
		bg_unique_material.set_shader_parameter("weight1" ,1.0/multi_color)
	pass

func set_range():
	var grid = $"../SubViewportContainer/SubViewport/CenterContainer/grid"
	if card.is_creature:
		for s:String in card.card_data['range']:
			var t = grid.get_node(s.replace(".","_"))
			t.show()
	else:
		grid.hide()
func set_card_art(texture: Texture2D):
	$"../SubViewportContainer/SubViewport/Panel/front/art".texture = texture
	scale_sprite_preserving_center($"../SubViewportContainer/SubViewport/Panel/front/art")
func add_mana_symbols():
	card.m_container = $"../SubViewportContainer/SubViewport/ManaCostContainer"
	if card.m_container:
		for child in card.m_container.get_children():
			child.queue_free()
		
		# Parse cost string and create symbols
		var symbols = []
		var total_symbols_width = 0.0
		var symbol_size = Vector2(24, 24)  # Adjust based on your symbol size
		
		# First pass: create all symbols and calculate total width
		for i in card.mana_cost.keys():
			if card.mana_cost[i] > 0:
				for j in range(card.mana_cost[i]):
					var symbol = Sprite2D.new()
					symbol.texture = load("res://assets/symbol/%s.png" % i)
					symbol.scale = Vector2(0.75, 0.75)  # Adjust scale if needed
					symbols.append(symbol)
					total_symbols_width += symbol_size.x
		
		# Calculate starting position for centering
		var container_width = card.m_container.size.x
		#var start_x = (container_width - total_symbols_width) / 2
		var start_x = 15
		# Second pass: position and add symbols
		var current_x = start_x
		if len(symbols) == 1:
			var symbol = symbols[0]
			symbol.position.x = 3
			symbol.position.y = 0  # Center vertically
			card.m_container.add_child(symbol)
		else:
			for symbol in symbols:
				symbol.position.x = current_x-(16 * symbol.scale.x)
				symbol.position.y = 0  # Center vertically
				card.m_container.add_child(symbol)
				current_x += symbol_size.x
func scale_sprite_preserving_center(sprite: Sprite2D, frame_size: Vector2 = Vector2(160, 140), fill: bool = false) -> void:
	if sprite.texture == null:
		return

	var tex_size = sprite.texture.get_size()
	var scale_factor: float

	if fill:
		scale_factor = max(frame_size.x / tex_size.x, frame_size.y / tex_size.y)
	else:
		scale_factor = min(frame_size.x / tex_size.x, frame_size.y / tex_size.y)

	sprite.scale = Vector2.ONE * scale_factor
	#sprite.offset = -tex_size / 2  # Center the texture visually
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
