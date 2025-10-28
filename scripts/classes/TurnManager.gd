extends Node
signal end_of_turn
signal end_phase
var orb_list = []
var turn = 1
var players: Array[Player] = []
var ui = UIManager.new()
var debug : Label
var game_manager:GameManager
var players_passed: int = 0
var player_mana_count = {
	"generic": 0,
	"red": 0,
	"blue": 0,
	"green": 0,
	"earth": 0,
	"white": 0,
	"black": 0}
var enemy_mana_count = {
	"generic": 0,
	"red": 1,
	"blue": 0,
	"green": 0,
	"earth": 0,
	"white": 0,
	"black": 0}
var is_selecting_mana = false
var dragging: Card
var targeting: Card
var player_mana_card_nr = 0
var enemy_mana_card_nr = 0
var waiting_for_input:bool = false
var board_slots: Dictionary
enum TurnEnum  {
	DRAW,
	MANA_SELECT,
	MANA_CREATE,
	MAIN,
	ATTACK,
	WAITING_FOR_INPUT,
	END
}
var current_phase :TurnEnum
var priority = true
var player_orbs = {
	"generic": [],
	"red": [],
	"blue": [],
	"green": [],
	"earth": [],
	"white": [],
	"black": []}
var enemy_orbs = {"generic": [],
	"red": [],
	"blue": [],
	"green": [],
	"earth": [],
	"white": [],
	"black": []}
var highlighted_slots : Array[Area2D] = []
var highlighted: Card

enum TargetKindEnum  {
	ATTACK,
	EFFECT
}
var Target_kind : TargetKindEnum
var stack = []

func push_to_stack(effect: Effect_class, ctx: Dictionary):
	stack.append({"effect": effect, "context": ctx})
func resolve_stack():
	while stack.size() > 0:
		var top = stack.pop_back()
		await EffectRunner.apply_effect(top.effect, top.context)
func reset_highlited():
	for node:Area2D in highlighted_slots:
		node.og_color = Vector4(0,0,0,0)
func end_turn():
	print("end_phase")
	await  game_manager.gamestate.end_phase_triggers()
	emit_signal("end_of_turn")
	
	await  game_manager.gamestate.on_turn_end_triggers()
	
	turn += 1
	current_phase = TurnEnum.DRAW
	priority = !priority
	print("end_of_turn")
	
	#is_selecting_mana = true
func _pass_priority():
	priority = !priority
func start_turn():
	is_selecting_mana = true
	current_phase = TurnEnum.MANA_SELECT
func finish_mana_creation():
	for player in players:
		if player.mana_created == false:
			return null
	for player in players:
		player.mana_created = false
	current_phase = TurnEnum.MAIN
func finish_draw():
	var i = 0
	for pl in players:
		pl.player_hand.reset()
		if pl.did_draw:
			i +=1
	if i == len(players):
		for pl in players:
			pl.did_draw = false
		current_phase = TurnEnum.MANA_SELECT
	_pass_priority()
	
func handle_stack_phase():
	var game = game_manager.gamestate
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
		print("top",top)
		if top:
			await EffectRunner.apply_effect(top.effect, top.context)
	print("=== STACK END ===")
	
func handle_priority(game: GameState):
	
	print("Player " if priority else "enemy ", "has priority:"+ str(players_passed))
	var player = players[0] if priority else players[1]
	
	# Ask player to respond (UI prompt or AI logic)
	var response = await player.request_response(game)
	print(response)
	if response in [null,"{  }",{}]:
		# Pass priority
		priority = not priority
		players_passed += 1
		if players_passed == 2:
			players_passed = 0
			waiting_for_input = false
	else:
		# Player responded with a new effect → push it
		game.push_to_stack(response)
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
		current_phase = TurnEnum.MANA_CREATE
		print("finish mana select")
	else:
		return null
