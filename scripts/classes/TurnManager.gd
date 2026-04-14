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
