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
@onready var attack = $attack

	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	b_index = buttons.z_index
	name_panel.text = card.state.card_name
	health_panel.text = str(card.state.toughness)
	power_panel.text = str(card.state.power)
	var unique_material:Material 
	var sprites = [$"../Playable",$"../SubViewportContainer",$"../Summoning_sickness",$"../Back/Sprite2D"]
	for sprite in sprites:
		var mat = sprite.material
		if mat and mat is ShaderMaterial:
			unique_material = mat.duplicate()
			sprite.material = unique_material
	subvp.material.set_shader_parameter("destroy", false)
	card.state.pt_changed.connect(update_pt)

	pass # Replace with function body.
	
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

	pass
	
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
	for color in card.state.mana_cost.keys():
		if card.state.mana_cost[color] and color != "generic":
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
	if card.state.is_creature:
		for s:String in card.state.card_data['range']:
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
	if card.state.can_be_payed(TurnManager.game_manager.gamestate,card.state.mana_cost) and is_dragging:
		card.state.controller.board.check_card(card,TurnManager.game_manager.gamestate)

func _on_mouse_entered():
	card.card_index = card.z_index
	if card.state.face_up and card.state.card_location != CardState.le.mana:
		card.movement.highlighted = true
		TurnManager.highlighted = card
		card.z_index = card.card_index + 10
		card.movement.animate_scale(card.hover_scale)

func burnCard(_state:CardState):
	var rng = RandomNumberGenerator.new()
	var direction := rng.randf_range(0.0, 360.0)
	TurnManager.waiting_for_input = true
	if subvp.material and subvp.material is ShaderMaterial:
		subvp.material.set_shader_parameter("destroy", true)
		
		var tween = create_tween()
		# set burning direction in degrees
		subvp.material.set_shader_parameter("direction", direction)
		# use tweens to animate the progress value
		tween.tween_method(up, -1.5, 1.5, 1.0)
		tween.tween_callback(card.send_to_grave)

func up(value: float):
	if subvp.material:
		subvp.material.set_shader_parameter("progress", value)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if card.parts_highlighted:
		buttons.z_index = b_index + 10
	
	if Summoning_sickness.material is ShaderMaterial:
			Summoning_sickness.material.set_shader_parameter("ss", card.state.summoned_on_turn == TurnManager.turn)
	if card.state.face_up:
		if Flip_animator.current_state == Flip_animator.CardSide.BACK_VISIBLE:
			Flip_animator.flip_to_front()
			
		pass
	if card.state.player_controled  and TurnManager.current_phase == TurnManager.TurnEnum.MAIN:
		if card.state.can_be_payed(TurnManager.game_manager.gamestate,card.state.mana_cost) and card.state.card_location==CardState.le.hand and (card.state.is_creature or card.state.can_activate_effect):
			if Playable.material is ShaderMaterial:
				Playable.material.set_shader_parameter("is_glowing", true)
		else:
			if Playable.material is ShaderMaterial:
				Playable.material.set_shader_parameter("is_glowing", false)
	if valid_target:
		if target_overlay.material is ShaderMaterial:
			target_overlay.show()
			target_overlay.material.set_shader_parameter('Enable_Effects', true)
			target_overlay.material.set_shader_parameter('Border_Color', Vector4(1,1,0,0.5))
	elif TurnManager.targeting == null:
		target_overlay.hide()
		target_overlay.material.set_shader_parameter('Enable_Effects', false)
	if card.movement.highlighted and card.state.controller.is_human:
		buttons.visible = true
		#buttons.mouse_filter = Control.MOUSE_FILTER_PASS
		cd = 1
		if TurnManager.current_phase == TurnManager.TurnEnum.MAIN and card.state.can_attack(TurnManager.game_manager.gamestate) and TurnManager.current_phase == TurnManager.TurnEnum.MAIN:
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
