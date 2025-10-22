extends Resource
class_name GameState

var player_hand:Array[CardState]
var enemy_hand:Array[CardState]

var player_grave:Array[CardState]
var enemy_grave:Array[CardState]

var turn: int = 1

var player_mana:Array[CardState]
var enemy_mana:Array[CardState]



var board  ={
	'1-1':[],	'1-2':[],	'1-3':[],	'1-4':[],	'1-5':[],	'2-1':[],	'2-2':[],	'2-3':[],	'2-4':[],	'2-5':[],	'3-1':[],	'3-2':[],	'3-3':[],	'3-4':[],	'3-5':[],	'4-1':[],	'4-2':[],	'4-3':[],	'4-4':[],	'4-5':[],	'5-1':[],	'5-2':[],	'5-3':[],	'5-4':[],	'5-5':[],	'6-1':[],	'6-2':[],	'6-3':[],	'6-4':[],	'6-5':[],

}
var board_e  ={
	'1-1':[],	'1-2':[],	'1-3':[],	'1-4':[],	'1-5':[],	'2-1':[],	'2-2':[],	'2-3':[],	'2-4':[],	'2-5':[],	'3-1':[],	'3-2':[],	'3-3':[],	'3-4':[],	'3-5':[],	'4-1':[],	'4-2':[],	'4-3':[],	'4-4':[],	'4-5':[],	'5-1':[],	'5-2':[],	'5-3':[],	'5-4':[],	'5-5':[],	'6-1':[],	'6-2':[],	'6-3':[],	'6-4':[],	'6-5':[],

}
func eval_gamestate():
	pass
func get_all_creatures():
	var res:Array=[]
	for key in board.keys():
		var board_pos = board[key]
		var vs:CardState = board_pos[0]
		if vs.is_creature:
			res.append(vs)
	return res
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func get_all_cards()->Array[CardState]:
	var res:Array[CardState] = []
	for c in player_grave+player_hand+player_mana+enemy_grave+enemy_hand+enemy_mana:
		res.append(c)
	for key in board.keys():
		var board_pos = board[key]
		for c in board_pos:
			res.append(c)
	return res
