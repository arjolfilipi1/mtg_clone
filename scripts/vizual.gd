extends Node
@onready var card:Card = $".."
@onready var attack_button = $"../ButtonsContainer/attack"
@onready var buttons = $"../ButtonsContainer"
@onready var target_overlay:ColorRect =$"../target"
@onready var subvp:= $"../SubViewportContainer"
@onready var Summoning_sickness:= $"../Summoning_sickness"
@onready var Flip_animator:= $"../Flip_animator"
@onready var Playable:= $"../Playable"
@onready var name_panel:= $"../SubViewportContainer/SubViewport/Panel/Name"
@onready var health_panel:= $"../SubViewportContainer/SubViewport/Panel/Health"
@onready var power_panel:= $"../SubViewportContainer/SubViewport/Panel/Power"
@onready var m_container = $"../SubViewportContainer/SubViewport/ManaCostContainer"
var valid_target := false
var b_index:int
var cd:float = 0.0


	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	b_index = buttons.z_index
	name_panel.text = card.card_name
	health_panel.text = str(card.card_data['toughness'])
	power_panel.text = str(card.card_data['power'])
	var unique_material:Material 
	var sprites = [$"../Playable",$"../SubViewportContainer",$"../Summoning_sickness",$"../Back/Sprite2D"]
	for sprite in sprites:
		var mat = sprite.material
		if mat and mat is ShaderMaterial:
			unique_material = mat.duplicate()
			sprite.material = unique_material
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
	"earth": Color(0.6, 0.4, 0.2)}
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
	if  multi_color > 2 :
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
	if m_container:
		for child in m_container.get_children():
			child.queue_free()
		
		# Parse cost string and create symbols
		var symbols = []
		var _total_symbols_width = 0.0
		var symbol_size = Vector2(24, 24)  # Adjust based on your symbol size
		
		# First pass: create all symbols and calculate total width
		for i in card.mana_cost.keys():
			if card.mana_cost[i] > 0:
				for j in range(card.mana_cost[i]):
					var symbol = Sprite2D.new()
					symbol.texture = load("res://assets/symbol/%s.png" % i)
					symbol.scale = Vector2(0.75, 0.75)  # Adjust scale if needed
					symbols.append(symbol)
					_total_symbols_width += symbol_size.x
		
		# Calculate starting position for centering
		var _container_width = m_container.size.x
		#var start_x = (container_width - total_symbols_width) / 2
		var start_x = 15
		# Second pass: position and add symbols
		var current_x = start_x
		if len(symbols) == 1:
			var symbol = symbols[0]
			symbol.position.x = 3
			symbol.position.y = 0  # Center vertically
			m_container.add_child(symbol)
		else:
			for symbol in symbols:
				symbol.position.x = current_x-(16 * symbol.scale.x)
				symbol.position.y = 0  # Center vertically
				m_container.add_child(symbol)
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
func set_drag_visuals(is_dragging: bool):
	subvp.material.set_shader_parameter("grayscale_amount",  1.0 if is_dragging else 0.0)
	subvp.material.set_shader_parameter("alpha_override", 0.5 if is_dragging else 1.0)
	if card.can_be_payed() and is_dragging:
		card.controller.board.check_card(card)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if card.parts_highlighted:
		buttons.z_index = b_index + 10
	
	if Summoning_sickness.material is ShaderMaterial:
			Summoning_sickness.material.set_shader_parameter("ss", card.summoned_on_turn == TurnManager.turn)
	if card.face_up:
		if Flip_animator.current_state == Flip_animator.CardState.BACK_VISIBLE:
			Flip_animator.flip_to_front()
			
		pass
	if card.player_controled  and TurnManager.current_phase == "main1":
		if card.can_be_payed() and card.card_location=="hand":
			if Playable.material is ShaderMaterial:
				Playable.material.set_shader_parameter("is_glowing", true)
		else:
			if Playable.material is ShaderMaterial:
				Playable.material.set_shader_parameter("is_glowing", false)
	if valid_target:
		if target_overlay.material is ShaderMaterial:
			target_overlay.show()
			target_overlay.material.set_shader_parameter('Enable_Effects', true)
			target_overlay.material.set_shader_parameter('Border_Color', Vector4(1,1,0,1))
	elif TurnManager.targeting == null:
		target_overlay.hide()
		target_overlay.material.set_shader_parameter('Enable_Effects', false)
	if card.movement.highlighted and card.controller.is_human:
		buttons.visible = true
		#buttons.mouse_filter = Control.MOUSE_FILTER_PASS
		cd = 1
		if card.can_attack() and TurnManager.current_phase == "main1":
			attack_button.visible = true
		else:
			attack_button.visible = false
	else:
		cd -= _delta
		if cd <= 0:
			pass
			#buttons.mouse_filter = Control.MOUSE_FILTER_IGNORE
			#buttons.visible = false
	pass
