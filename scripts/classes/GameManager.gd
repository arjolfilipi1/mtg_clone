extends Node
class_name GameManager
var player_deck :Node= null
var enemy_deck :Node= null
var player_hand :Node= null
var enemy_hand :Node= null
var player_board:Node= null
var enemy_board:Node= null
var player_mana_zone :Node= null
var enemy_mana_zone :Node= null
var enemy_ai :Node= null
var prio :Node= null
var debug :Node= null
var turn :Node= null
var high :Node= null
var confirm_overlay :Node= null
var sp:Node= null
var sl:Node= null
var stack_view :Node= null
var initialPosition 

var player1 : Player
var player2 : Player
var card_database = []
var last_card_drawn:Card
var is_player_turn = true
var current_player : Player
var cm:CombatManager
var gamestate:MTGGameState
var selected_card = null
var action_panel:Node= null
var tree:SceneTree
var p_overlay:Node
var e_overlay:Node
var player_deck_init:Array[int] = [2,3,4,5,6,0,1,5]
var enemy_deck_init:Array[int] = [0,1,2,3,4,5,6,3]
var setup_finished:=false

func store_gamestate():
	print(confirm_overlay)
	#print(gamestate.enemy_hand+gamestate.enemy_mana+gamestate.enemy_grave)



func select_card(card):
	selected_card = card

	var actions = gamestate.get_available_actions(card)
	action_panel.show_actions(card, actions)

func setup():
	gamestate = MTGGameState.new()
	gamestate.stack_changed.connect(TurnManager.handle_stack_phase)
	spawn_players()
	load_cards()
	start_game()
	TurnManager.end_phase.connect(gamestate.end_phase_triggers)
	TurnManager.end_of_turn.connect(gamestate.on_turn_end_triggers)
	cm = CombatManager.new()
	# Connect overlay signals
	setup_finished = true
	
func request_confirmation(action_message: String, on_confirm_callback: Callable) -> void:
	# Store the callback for later execution
	TurnManager.waiting_for_input = true
	confirm_overlay.meta = on_confirm_callback
	confirm_overlay.show_confirm(action_message)
	print("requested",confirm_overlay)
func _on_overlay_confirmed() -> void:
	# Execute the pending callback if it exists
	if confirm_overlay == null:
		push_error("GameManager: _on_overlay_confirmed called but confirm_overlay is null")
		return
	TurnManager.waiting_for_input = false
	var callback = confirm_overlay.meta
	if callback != confirm_overlay.null_meta:
		callback.call()
	else:
		print("it was null")
	print("confirmed for attack")
	confirm_overlay.meta = confirm_overlay.null_meta
	confirm_overlay.hide()
func _on_overlay_cancelled() -> void:
	# Clear the pending callback
	confirm_overlay.meta = confirm_overlay.null_meta
	TurnManager.waiting_for_input = false
	print("Action cancelled")
	confirm_overlay.hide()
func spawn_players():
	player1 = Player.new("You",player_mana_zone,player_hand,player_board,player_deck)
	player2 = Player.new("Enemy",enemy_mana_zone,enemy_hand,enemy_board,enemy_deck)
	
	#player1.is_active = true
	player1.is_human = true  # You can define this in Player.gd

	#player2.is_active = false
	player2.is_human = false
	
	enemy_ai.pl = player2
	TurnManager.players = [player1,player2]
	#Player.add_child(player1)
	#Player.add_child(player2)
#
	#Player.append(player1)
	#Player.append(player2)

	#current_player_index = 0  # Player starts
	#setup_initial_state()
func load_cards():
	var file = FileAccess.open("res://data/card.json", FileAccess.READ)
	card_database = JSON.parse_string(file.get_as_text())
func register_main(n:Node):
	tree = n.get_tree()
	initialPosition =  n.get_node("PlayerDeck").global_position
	player_deck =n.get_node("PlayerDeck")
	enemy_deck = n.get_node("EnemyDeck")
	player_hand =n.get_node("PlayerHand")
	enemy_hand = n.get_node("EnemyHand")
	player_board = n.get_node("PlayerBoard")
	enemy_board = n.get_node("EnemyBoard")
	player_mana_zone = n.get_node("PlayerMana")
	enemy_mana_zone = n.get_node("EnemyMana")
	enemy_ai = n.get_node("EnemyAI")
	prio =n.get_node("debug2/Priority") 
	debug = n.get_node("ScrollContainer/debug")
	turn = n.get_node("debug2/turn")
	high = n.get_node("debug2/high")
	confirm_overlay = n.get_node("ConfirmOverlay")
	confirm_overlay.get_node("VBoxContainer/ButtonContainer/ConfirmButton").pressed.connect(_on_overlay_confirmed)
	confirm_overlay.get_node("VBoxContainer/ButtonContainer/CancelButton").pressed.connect(_on_overlay_cancelled)
	sp = n.get_node("debug2/pos")
	sl = n.get_node("debug2/selected")
	stack_view = n.get_node("StackListViewer")
	action_panel =n.get_node("ActionPanel")
	p_overlay =n.get_node("PlayerBoard/sprite/OverlayEffect")
	e_overlay =n.get_node("EnemyBoard/sprite/OverlayEffect")
	setup()
	UI_Manager.setup()
func start_game():
	#Engine.time_scale = 0.1
	TurnManager.current_phase = GameEnums.TurnEnum.DRAW
	UI_Manager.debug = debug
	for i in range(5):
		var card_id = player_deck_init.pop_at(0)
		initial_draw_card(player1,card_id)
		card_id = enemy_deck_init.pop_at(0)
		initial_draw_card(player2,card_id)
	gamestate.player_deck = player_deck_init
	gamestate.enemy_deck = enemy_deck_init
	#while player_hand.drawTween.is_running:
		#pass
	TurnManager.start_turn()
func initial_draw_card(_player:Player,card_id):
	var random_card = card_database[card_id]
	var card = load("res://scenes/Card.tscn").instantiate()
	card.setup(random_card,_player)
	card.state.card_location = GameEnums.CardZone.HAND
	if _player.is_human:
		gamestate.player_hand.append(card.state)
	else:
		gamestate.enemy_hand.append(card.state)
	_player.player_hand.add_child(card)
	_player.player_hand.initial_draw(initialPosition)

func draw_card(card: Card, from_pos: Vector2, to_pos: Vector2, duration: float = 0.5) -> void:
	
	card.position = from_pos
	card.rotation = deg_to_rad(-20)
	card.scale = Vector2(0.8, 0.8)
	card.global_position = from_pos
	last_card_drawn = card
	card.state.card_location = GameEnums.CardZone.HAND
	# Keep card in current parent during tweening
	var tween = get_tree().create_tween()
	tween.set_parallel(true)

	tween.tween_property(card, "global_position", to_pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "rotation", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Wait for tween to finish before reparenting
	await tween.finished
	# Convert global position to new parent's local coordinates
	TurnManager.finish_draw()
	card.state.controller.player_hand.reset()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if TurnManager.current_phase == GameEnums.TurnEnum.ATTACK:
				_on_cancel_attack_pressed()
				get_viewport().set_input_as_handled()
				
func _process(_delta: float) -> void:
	if not setup_finished:
		return
	if not confirm_overlay:
		print("deleted",_delta)
	if  len(gamestate.stack) > 0 :
		
		stack_view.show_cards(gamestate.stack)
	else:
		stack_view.clear()
	#debug putton size
	if UI_Manager.highlighted:

		sp.text = "vt" + str(gamestate.player_mana )
		sl.text = str(gamestate.enemy_deck )
		#sl.text = "eh:"+str( len(gamestate.enemy_hand ))+"em:"+str( len(gamestate.enemy_mana )) + "eg:"+str( len(gamestate.enemy_grave ))
	if TurnManager.priority:
		current_player = player1
		p_overlay.visible = true
		e_overlay.visible = false
	else:
		e_overlay.visible = true
		p_overlay.visible = false
		current_player = player2 
	if TurnManager.current_phase == GameEnums.TurnEnum.MANA_CREATE:
		current_player.reset_mana()
		
		current_player.create_mana()
		#await get_tree().create_timer(1.0).timeout  # Small delay
	if TurnManager.current_phase == GameEnums.TurnEnum.MANA_SELECT:
		TurnManager.is_selecting_mana = true
	if TurnManager.current_phase == GameEnums.TurnEnum.DRAW and current_player.did_draw == false:
		
		UI_Manager.debug.text += current_player.player_name+" drawing \n"
		current_player.draw(gamestate)
	
	prio.text = current_player.player_name
	turn.text = GameEnums.TurnEnum.keys()[ TurnManager.current_phase]
	high.text = UI_Manager.selected+ " " + str(TurnManager.targeting) if UI_Manager.highlighted else "No focus"

func _on_cancel_attack_pressed() -> void:
	AttackManager.cancel_attack()
	confirm_overlay.hide()

func _on_end_turn_button_pressed() -> void:
	TurnManager.end_turn()

func mana_on_area_2d_input_event(_viewport: Node, _event: InputEvent, _shape_idx: int) -> void:
	if _event is InputEventMouseButton and _event.pressed and _event.button_index == MOUSE_BUTTON_LEFT:
		$"../CardListViewer".show_cards(gamestate.player_mana, "Mana")
