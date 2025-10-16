extends Node
var orb_list = []
var turn = 1
var players: Array[Player] = []
var debug : Label
var game_manager:GameManager
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
var dragging: Node
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
func reset_highlited():
	for node:Area2D in highlighted_slots:
		node.og_color = Vector4(0,0,0,0)
func end_turn():
	turn += 1
	current_phase = TurnEnum.DRAW
	priority = !priority
	#is_selecting_mana = true
	#print(turn)
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
		if pl.did_draw:
			i +=1
	if i == len(players):
		for pl in players:
			pl.did_draw = false
		current_phase = TurnEnum.MANA_SELECT
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
		current_phase = TurnEnum.MANA_CREATE
		print("finish mana select")
	else:
		return null

func cost_to_list(raw_list_string):
		# Convert single quotes to double quotes (JSON uses double quotes)
	raw_list_string = raw_list_string.replace("'", '"')

	# Parse the string into an actual array
	var result = JSON.parse_string(raw_list_string)
	return result
