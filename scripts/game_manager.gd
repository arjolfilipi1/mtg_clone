extends Node

@onready var player_deck := $"../PlayerDeck"
@onready var enemy_deck := $"../EnemyDeck"
@onready var player_hand = $"../PlayerHand"
@onready var enemy_hand = $"../EnemyHand"
@onready var player_board = $"../PlayerBoard"
@onready var enemy_board = $"../EnemyBoard"
@onready var player_mana_zone = $"../PlayerMana"
@onready var enemy_mana_zone = $"../EnemyMana"
@onready var enemy_ai = $"../EnemyAI"
@onready var prio = $"../Priority"
@onready var debug = $"../debug"
@onready var turn = $"../turn"
@onready var high = $"../high"
var player1 : Player
var player2 : Player
var card_database = []
var last_card_drawn:Node
var is_player_turn = true
var current_player : Player
func _ready():
	spawn_players()
	load_cards()
	start_game()
func spawn_players():
	player1 = Player.new("You",player_mana_zone,player_hand,player_board,player_deck)
	player2 = Player.new("Enemy",enemy_mana_zone,enemy_hand,enemy_board,enemy_deck)
	
	player1.is_active = true
	player1.is_human = true  # You can define this in Player.gd

	player2.is_active = false
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
	TurnManager.current_phase = TurnManager.turn_phases[0]
	TurnManager.debug = debug
	for i in range(5):
		initial_draw_card(player1)
		initial_draw_card(player2,false)
	#while player_hand.drawTween.is_running:
		#pass
	TurnManager.start_turn()
func initial_draw_card(_player,player = true):
	var random_card = card_database[randi() % card_database.size()]
	var card = preload("res://scenes/Card.tscn").instantiate()
	card.setup(random_card,player,_player)
	card.card_location = "hand"
	_player.player_hand.add_child(card)
	_player.player_hand.initial_draw(initialPosition)

func draw_card(card: Control, from_pos: Vector2, to_pos: Vector2, duration: float = 0.5) -> void:
	
	card.position = from_pos
	card.rotation = deg_to_rad(-20)
	card.scale = Vector2(0.8, 0.8)
	card.global_position = from_pos
	last_card_drawn = card
	card.card_location = "hand"
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
	card.controller.player_hand.reset()
	
func _process(_delta: float) -> void:
	if TurnManager.priority:
		current_player = player1
	else:
		current_player = player2 
	if TurnManager.current_phase == "mana_create":
		current_player.reset_mana()
		
		current_player.create_mana()
		#await get_tree().create_timer(1.0).timeout  # Small delay
	if TurnManager.current_phase == "mana_select":
		TurnManager.is_selecting_mana = true
	if TurnManager.current_phase == "draw" and current_player.did_draw == false:
		var card = preload("res://scenes/Card.tscn").instantiate()
		var random_card = card_database[randi() % card_database.size()]
		card.card_location = "hand"
		card.controller = current_player
		card.setup(random_card,current_player.is_human,current_player)
		current_player.player_hand.add_child(card)
		draw_card(card, current_player.deck.position, current_player.player_hand.position)
		TurnManager.debug.text += current_player.player_name+" drawing \n"
		current_player.did_draw = true
	if TurnManager.current_phase == "main1" and TurnManager.priority:
		$"../EndTurnButton".disabled = false
	else:
		$"../EndTurnButton".disabled = true
	prio.text = current_player.player_name
	turn.text = TurnManager.current_phase
	high.text = TurnManager.highlighted.card_name+ str(TurnManager.highlighted.scale) if TurnManager.highlighted else "No focus"

func _on_end_turn_button_pressed() -> void:
	TurnManager.end_turn()
	pass # Replace with function body.
