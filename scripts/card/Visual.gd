extends Node
#parent node
@onready var card:Card = $".."
#attach button


@onready var card_sprite: Sprite2D = $"../SubViewportContainer/SubViewport/Panel/front/backgourd"
@onready var grid = $"../SubViewportContainer/SubViewport/CenterContainer/grid"
#tooltip container

#color to indicate that card can be attacked
@onready var target_overlay:ColorRect =$"../target"
#subviewport to hold the card image, made so that shaders can be applied individualy
@onready var subvp:= $"../SubViewportContainer"
#color to show that creature has ss
@onready var Summoning_sickness:= $"../Summoning_sickness"
#node that holds the logic so that card can flip over
@onready var Flip_animator:= $"../Flip_animator"
#color to show that card in hand can be played
@onready var Playable:= $"../Playable"
@onready var effect := $"../effect"
var effect_progress:float = 0.0
@onready var name_panel:= $"../SubViewportContainer/SubViewport/Panel/Name"
@onready var health_panel:= $"../SubViewportContainer/SubViewport/Panel/Health"
@onready var power_panel:= $"../SubViewportContainer/SubViewport/Panel/Power"
@onready var m_container = $"../SubViewportContainer/SubViewport/ManaCostContainer"
#logic for selection by player
var valid_target := false
var selected_target := false
@onready var tar:Sprite2D= $"../tar"
@onready var sel:Sprite2D= $"../sel"
#index of the tooltip
var b_index:int
#highlight time for the buttons 
var cd:float = 0.0
var burn_tween: Tween = null
#node that has the attack animation logic
@onready var attack = $attack

func _exit_tree():
	"""Clean up burn tween"""
	if burn_tween and burn_tween.is_valid():
		burn_tween.kill()
		burn_tween = null

func show_target_highlight(enabled):
	tar.visible = enabled

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tar.visible = false
	sel.visible = false

	name_panel.text = card.state.card_name
	health_panel.text = str(card.state.toughness)
	power_panel.text = str(card.state.power)
	var unique_material:Material 
	var sprites = [Playable,subvp,Summoning_sickness,$"../Back/Sprite2D",effect]
	for sprite in sprites:
		var mat = sprite.material
		if mat and mat is ShaderMaterial:
			unique_material = mat.duplicate()
			sprite.material = unique_material
	subvp.material.set_shader_parameter("destroy", false)
	card.state.pt_changed.connect(update_pt)
	effect.visible = false

#show effect overlay
func show_effect(_effect:Effect_class):
	print("showing effect of " +card.state.card_name)
	effect.visible = true
	if effect.material and effect.material is ShaderMaterial:
		effect.material.set_shader_parameter("activated", true)
#updates the power/toughtness visual
func update_pt(c:CardState)->void:
	if c == card.state:
		var style = StyleBoxFlat.new()
		power_panel.text = str(card.state.power)
		if card.state.card_data['power'] > card.state.power:
			power_panel.add_theme_color_override("font_color", Color.RED)
		elif card.state.card_data['power'] < card.state.power:
			style.bg_color = Color(0, 0, 1) # blue color
			power_panel.add_theme_color_override("font_color", Color.BLUE)
		else:
			power_panel.add_theme_color_override("font_color", Color.BLACK)
		health_panel.text = str(card.state.toughness)
		if card.state.card_data['toughness'] > card.state.toughness:
			health_panel.add_theme_color_override("font_color", Color.RED)
		elif card.state.card_data['toughness'] < card.state.toughness:
			health_panel.add_theme_color_override("font_color", Color.BLUE)
		else:
			health_panel.add_theme_color_override("font_color", Color.BLACK)


#sets the card background
func set_background_color():
	#ShaderMaterial
	
	card_sprite = $"../SubViewportContainer/SubViewport/Panel/front/backgourd"
	
# Duplicate the material (shallow copy still shares the shader, which is fine)
	var bg_unique_material := card_sprite.material.duplicate()
	card_sprite.material = bg_unique_material
	var color_list = []
	var max_str = ""
	var max_nr = 0
	for color in card.state.mana_cost.keys():
		if card.state.mana_cost[color] and color != "generic":
			color_list.append(color)
			if card.state.mana_cost[color] > max_nr:
				max_str = color
				max_nr = card.state.mana_cost[color]
	if max_str != "":
		card_sprite.texture = load("res://assets/card/%s.png" % max_str)
	var multi_color = len(color_list)
	if  multi_color:
		#if color_list[0] :
			#bg_unique_material.set_shader_parameter("mana_color1" ,_MANA_COLORS[color_list[0]])
			#bg_unique_material.set_shader_parameter("weight1" ,1.0/multi_color)
		if  multi_color > 1:
			bg_unique_material.set_shader_parameter("mana_color2" ,GameEnums._MANA_COLORS[color_list[1]])
			bg_unique_material.set_shader_parameter("weight2" ,1.0/multi_color)
		if  multi_color > 2 :
			bg_unique_material.set_shader_parameter("mana_color3" ,GameEnums._MANA_COLORS[color_list[2]])
			bg_unique_material.set_shader_parameter("weight3" ,1.0/multi_color)
		pass
#each card has range, the card has a little square that it is shown when the card can attack that range
func set_range():
	
	if card.state.is_creature:
		for s:String in card.state.card_data['range']:
			var t = grid.get_node(s.replace(".","_"))
			t.show()
	else:
		grid.hide()
#sets the card art
func set_card_art(texture: Texture2D):
	$"../SubViewportContainer/SubViewport/Panel/front/art".texture = texture
	scale_sprite_preserving_center($"../SubViewportContainer/SubViewport/Panel/front/art")

#sets the card mana symbols for the cost
func add_mana_symbols():
	if m_container:
		for child in m_container.get_children():
			child.queue_free()
		
		# Parse cost string and create symbols
		var symbols = []
		var _total_symbols_width = 0.0
		var symbol_size = Vector2(24, 24)  # Adjust based on your symbol size
		
		# First pass: create all symbols and calculate total width
		for i in card.state.mana_cost.keys():
			if card.state.mana_cost[i] > 0:
				for j in range(card.state.mana_cost[i]):
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

#scales the card art
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
	if card.state.can_be_payed(Game_Manager.gamestate,card.state.mana_cost) and is_dragging:
		card.state.controller.board.check_card(card,Game_Manager.gamestate)



#burn effect when card is destroyed
func burnCard(_state:CardState):
	var rng = RandomNumberGenerator.new()
	var direction := rng.randf_range(0.0, 360.0)
	TurnManager.waiting_for_input = true
	
	if subvp.material and subvp.material is ShaderMaterial:
		subvp.material.set_shader_parameter("destroy", true)
		
		# Kill existing burn tween
		if burn_tween and burn_tween.is_valid():
			burn_tween.kill()
		
		burn_tween = create_tween()
		subvp.material.set_shader_parameter("direction", direction)
		burn_tween.tween_method(burn_update, -1.5, 1.5, 1.0)
		burn_tween.tween_callback(card.send_to_grave)
		await burn_tween.finished
		burn_tween = null
#
func burn_update(value: float):
	if subvp.material:
		subvp.material.set_shader_parameter("progress", value)




# Simplify _process - remove button visibility logic (moved to highlight_manager)
func _process(_delta: float) -> void:
	# Effect animation
	if effect.visible:
		if effect_progress < 1.0:
			effect_progress += _delta
			if effect.material and effect.material is ShaderMaterial:
				effect.material.set_shader_parameter("progress", effect_progress)
		else:
			effect.visible = false
			effect_progress = 0.0
	
	# Card face animation
	if card.state.face_up:
		if Flip_animator.current_state == GameEnums.CardSide.BACK:
			Flip_animator.flip_to_front()
	
	# Playable glow effect (hand cards only)
	if card.state.player_controled and TurnManager.current_phase == GameEnums.TurnEnum.MAIN:
		var can_pay = card.state.can_be_payed(Game_Manager.gamestate, card.state.mana_cost)
		var in_hand = card.state.card_location == GameEnums.CardZone.HAND
		var has_effect = card.state.is_creature or card.state.can_activate_effect
		
		if can_pay and in_hand and has_effect:
			if Playable.material is ShaderMaterial:
				Playable.material.set_shader_parameter("is_glowing", true)
		else:
			if Playable.material is ShaderMaterial:
				Playable.material.set_shader_parameter("is_glowing", false)
	
	# Target overlay (remains same)
	_update_target_overlay()
	
	# Buttons visibility is now handled by highlight_manager
	# Remove the old button visibility logic

func _update_target_overlay():
	if selected_target:
		if target_overlay.material is ShaderMaterial:
			target_overlay.show()
			target_overlay.material.set_shader_parameter('Enable_Effects', true)
			target_overlay.material.set_shader_parameter('Border_Color', Vector4(0.1,1,0.1,0.5))
	elif valid_target:
		if target_overlay.material is ShaderMaterial:
			target_overlay.show()
			target_overlay.material.set_shader_parameter('Enable_Effects', true)
			target_overlay.material.set_shader_parameter('Border_Color', Vector4(1,1,0,0.5))
	elif not selected_target and not valid_target:
		target_overlay.hide()
		target_overlay.material.set_shader_parameter('Enable_Effects', false)
