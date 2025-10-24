extends Node
class_name GameManager
@onready var player_deck := $"../PlayerDeck"
@onready var enemy_deck := $"../EnemyDeck"
@onready var player_hand = $"../PlayerHand"
@onready var enemy_hand = $"../EnemyHand"
@onready var player_board = $"../PlayerBoard"
@onready var enemy_board = $"../EnemyBoard"
@onready var player_mana_zone = $"../PlayerMana"
@onready var enemy_mana_zone = $"../EnemyMana"
@onready var enemy_ai = $"../EnemyAI"
@onready var prio = $"../debug2/Priority"
@onready var debug = $"../ScrollContainer/debug"
@onready var turn = $"../debug2/turn"
@onready var high = $"../debug2/high"
@onready var confirm_overlay = $"../ConfirmOverlay"
@onready var sp:Label = $"../debug2/pos"
@onready var sl:Label = $"../debug2/selected"
var player1 : Player
var player2 : Player
var card_database = []
var last_card_drawn:Card
var is_player_turn = true
var current_player : Player
var cm:CombatManager
var gamestate:GameState

var player_deck_init:Array[int] = [2,3,4,5,6,0,1,5]
var enemy_deck_init:Array[int] = [0,1,2,3,4,5,6,3]

func store_gamestate():
	$"../CardListViewer".show_cards(gamestate.player_mana, "Mana")
	print(gamestate.player_hand+gamestate.player_mana+gamestate.player_grave)
	print(gamestate.enemy_hand+gamestate.enemy_mana+gamestate.enemy_grave)
	pass
	
func _ready():
	TurnManager.game_manager = self
	gamestate = GameState.new()
	spawn_players()
	load_cards()
	start_game()
	TurnManager.end_phase.connect(gamestate.end_phase_triggers)
	TurnManager.end_of_turn.connect(gamestate.on_turn_end_triggers)
	for c in enemy_board.get_children():
		if c.is_in_group("enemy_slots"):
			TurnManager.board_slots[c.name] = c
	for c in player_board.get_children():
		if c.is_in_group("player_slots"):
			TurnManager.board_slots[c.name] = c

	cm = CombatManager.new()
	# Connect overlay signals

	
func request_confirmation(action_message: String, on_confirm_callback: Callable) -> void:
	# Store the callback for later execution
	TurnManager.waiting_for_input = true
	confirm_overlay.meta = on_confirm_callback
	confirm_overlay.show_confirm(action_message)

func _on_overlay_confirmed() -> void:
	# Execute the pending callback if it exists
	TurnManager.waiting_for_input = false
	var callback = confirm_overlay.meta
	if callback != confirm_overlay.null_meta:
		callback.call()
	else:
		print("it was null")
	confirm_overlay.meta = confirm_overlay.null_meta

func _on_overlay_cancelled() -> void:
	# Clear the pending callback
	confirm_overlay.meta = confirm_overlay.null_meta
	TurnManager.waiting_for_input = false
	print("Action cancelled")
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
	
@onready var initialPosition =  $"../PlayerDeck".global_position
func start_game():
	#Engine.time_scale = 0.1
	TurnManager.current_phase = TurnManager.TurnEnum.DRAW
	TurnManager.debug = debug
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
func initial_draw_card(_player:Player,card_id,player = true):
	var random_card = card_database[card_id]
	var card = preload("res://scenes/Card.tscn").instantiate()
	card.setup(random_card,_player)
	card.state.card_location = card.state.le.hand
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
	card.state.card_location = CardState.le.hand
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
			if TurnManager.targeting and TurnManager.Target_kind == TurnManager.TargetKindEnum.ATTACK:
				_on_cancel_attack_pressed()

			get_viewport().set_input_as_handled()  # Prevent other nodes from processing
func _process(_delta: float) -> void:
	
	#debug putton size
	if TurnManager.highlighted:

		sp.text = "vt" + str(TurnManager.highlighted.visual.valid_target )
		sl.text = str(gamestate.enemy_deck )
		#sl.text = "eh:"+str( len(gamestate.enemy_hand ))+"em:"+str( len(gamestate.enemy_mana )) + "eg:"+str( len(gamestate.enemy_grave ))
	if TurnManager.priority:
		current_player = player1
		$"../PlayerBoard/sprite/OverlayEffect".visible = true
		$"../EnemyBoard/sprite/OverlayEffect".visible = false
	else:
		$"../EnemyBoard/sprite/OverlayEffect".visible = true
		$"../PlayerBoard/sprite/OverlayEffect".visible = false
		current_player = player2 
	if TurnManager.current_phase == TurnManager.TurnEnum.MANA_CREATE:
		current_player.reset_mana()
		
		current_player.create_mana()
		#await get_tree().create_timer(1.0).timeout  # Small delay
	if TurnManager.current_phase == TurnManager.TurnEnum.MANA_SELECT:
		TurnManager.is_selecting_mana = true
	if TurnManager.current_phase == TurnManager.TurnEnum.DRAW and current_player.did_draw == false:
		
		TurnManager.debug.text += current_player.player_name+" drawing \n"
		current_player.draw(gamestate)
	if TurnManager.current_phase == TurnManager.TurnEnum.MAIN and TurnManager.priority:
		$"../ButtonContainer/EndTurnButton".disabled = false
	else:
		$"../ButtonContainer/EndTurnButton".disabled = true
	if TurnManager.current_phase == TurnManager.TurnEnum.ATTACK and TurnManager.priority:
		$"../ButtonContainer/Cancel attack".disabled = false
	else:
		$"../ButtonContainer/Cancel attack".disabled = true
	prio.text = current_player.player_name
	turn.text = TurnManager.TurnEnum.keys()[ TurnManager.current_phase]
	high.text = TurnManager.highlighted.state.card_name+ str(snappedf( TurnManager.highlighted.size.x,0.01)) if TurnManager.highlighted else "No focus"
func _on_cancel_attack_pressed() -> void:
	if TurnManager.targeting:
		TurnManager.targeting.movement.targeting_arrow.is_targeting = false
		TurnManager.targeting.movement.targeting_arrow.complete_targeting()
		
	TurnManager.reset_highlited()
	#TurnManager.targeting = null
	TurnManager.current_phase = TurnManager.TurnEnum.MAIN
	pass # Replace with function body.
func _on_end_turn_button_pressed() -> void:
	TurnManager.end_turn()
	pass # Replace with function body.
