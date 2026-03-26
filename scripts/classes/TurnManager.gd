extends Node
signal end_of_turn
signal end_phase

var turn = 1
var players: Array[Player] = []
var players_passed: int = 0
var is_selecting_mana = false
var dragging: Card
var targeting: Card
var waiting_for_input:bool = false
var current_phase :GameEnums.TurnEnum = GameEnums.TurnEnum.DRAW
var priority = true

var target_kind: GameEnums.TargetKind = GameEnums.TargetKind.ATTACK

var selected_slot_name: String = ""


func end_turn():
	print("end_phase")
	await  Game_Manager.gamestate.end_phase_triggers()
	emit_signal("end_of_turn")
	
	await  Game_Manager.gamestate.on_turn_end_triggers()
	
	turn += 1
	current_phase = GameEnums.TurnEnum.DRAW
	priority = !priority
	print("end_of_turn")
	
	#is_selecting_mana = true
func _pass_priority():
	priority = !priority
func start_turn():
	is_selecting_mana = true
	current_phase = GameEnums.TurnEnum.MANA_SELECT
func finish_mana_creation():
	for player in players:
		if player.mana_created == false:
			return null
	for player in players:
		player.mana_created = false
	current_phase = GameEnums.TurnEnum.MAIN
func finish_draw():
	var i = 0
	for pl in players:
		pl.player_hand.reset()
		if pl.did_draw:
			i +=1
	if i == len(players):
		for pl in players:
			pl.did_draw = false
		current_phase = GameEnums.TurnEnum.MANA_SELECT
	_pass_priority()
	
func handle_stack_phase():
	var game = Game_Manager.gamestate
	if len(game.stack) == 0:
		return

	print("=== STACK START ===")
	while not game.stack.is_empty():
		waiting_for_input = true

		while waiting_for_input:
			await handle_priority(game)
		print("stack", game.stack.size())
		# both passed, resolve top effect
		var top = game.pop_from_stack()
		
		if top:
			print("top",top.source.card_name)
			await EffectRunner.apply_effect(top.effect, top.context)
	print("=== STACK END ===")
	
func handle_priority(game: MTGGameState):
	
	print("Player " if priority else "enemy ", "has priority:"+ str(players_passed))
	var player = players[0] if priority else players[1]
	
	# Ask player to respond (UI prompt or AI logic)
	var response = await player.request_response(game)
	
	if response in [null,"{  }",{}]:
		# Pass priority
		priority = not priority
		players_passed += 1
		if players_passed == 2:
			players_passed = 0
			waiting_for_input = false
	else:
		# Player responded with a new effect → push it
		response.source.apply_effect(response.effect,Game_Manager.gamestate)
		priority = not priority # other player gets chance next
func finish_mana_selection():
	var i = 0
	for pl in players:
		if pl.mana_selected:
			i +=1
	if i == len(players):
		for pl in players:
			pl.mana_selected = false
		is_selecting_mana = false
		current_phase = GameEnums.TurnEnum.MANA_CREATE
		print("finish mana select")
	else:
		return null
