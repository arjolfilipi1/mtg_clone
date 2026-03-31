extends Node


# The card that is currently declaring an attack
var attacker: Card = null
# Cards highlighted as valid targets this declaration
var highlighted_targets: Array[Card] = []

# --- Entry point ---
func begin_attack(attacking_card: Card, valid_target_states: Array) -> void:
	# Only one attack declaration at a time
	if attacker != null:
		return

	attacker = attacking_card
	TurnManager.current_phase = GameEnums.TurnEnum.ATTACK
	TurnManager.targeting = attacking_card

	# Convert CardState array to Card nodes and highlight them
	highlighted_targets.clear()
	for cs: CardState in valid_target_states:
		if cs.card_node and is_instance_valid(cs.card_node):
			highlighted_targets.append(cs.card_node)
			_highlight_target(cs.card_node, true)

	# Show the targeting arrow on the attacker
	if not attacking_card.is_ancestor_of(UI_Manager.targeting_arrow):
		attacking_card.add_child(UI_Manager.targeting_arrow)
	UI_Manager.targeting_arrow.initiate_targeting()

# --- Called from Movement.on_click when a valid target is clicked ---
func on_target_clicked(target_card: Card) -> void:
	if attacker == null:
		print("no attacker")
		return
	if target_card not in highlighted_targets:
		print("not target")
		return

	# Ask for confirmation before committing
	Game_Manager.request_confirmation(
		"Attack " + target_card.state.card_name + "?",
		func(): _confirm_attack(target_card)
	)

# --- Called when confirmation dialog is confirmed ---
func _confirm_attack(target_card: Card) -> void:
	if attacker == null:
		return
	var attacking := attacker
	_cleanup_highlights()
	UI_Manager.targeting_arrow.complete_targeting()
	# Play the slam animation; damage is applied inside Attack.gd on completion
	attacking.visual.attack.start_slam_attack(attacking, target_card)
	TurnManager.targeting = null
	TurnManager.current_phase = GameEnums.TurnEnum.MAIN
	print("here,",TurnManager.current_phase)
# --- Called from GameManager._input on right-click, or dialog cancel ---
func cancel_attack() -> void:
	if attacker == null:
		return
	UI_Manager.targeting_arrow.complete_targeting()
	_cleanup_highlights()
	TurnManager.targeting = null
	TurnManager.current_phase = GameEnums.TurnEnum.MAIN

# --- Highlight helpers ---
func _highlight_target(target: Card, enable: bool) -> void:
	if not target or not target.visual:
		return
	target.visual.tar.visible = enable
	target.visual.valid_target = enable
	if enable:
		target.pressed.connect(on_target_clicked)
		target.visual.target_overlay.show()
		target.visual.target_overlay.material.set_shader_parameter("Enable_Effects", true)
		target.visual.target_overlay.material.set_shader_parameter(
			"Border_Color", Vector4(0.1, 1, 0.1, 1)
		)
	else:
		target.pressed.disconnect(on_target_clicked)
		target.visual.tar.visible = false
		target.visual.valid_target = false

func _cleanup_highlights() -> void:
	for c in highlighted_targets:
		if is_instance_valid(c):
			_highlight_target(c, false)
	highlighted_targets.clear()
	attacker = null
