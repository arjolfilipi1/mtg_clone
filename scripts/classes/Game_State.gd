extends Resource
class_name GameState

var player_hand:Array[CardState]
var enemy_hand:Array[CardState]

var player_deck:Array[int] = []
var enemy_deck:Array[int] = []

var player_grave:Array[CardState]
var enemy_grave:Array[CardState]

var turn: int = 1

var player_mana:Array[CardState]
var enemy_mana:Array[CardState]

var stack: Array = []  # list of pending effects
signal stack_changed
var board  ={
	'1-1':[],	'1-2':[],	'1-3':[],	'1-4':[],	'1-5':[],	'2-1':[],	'2-2':[],	'2-3':[],	'2-4':[],	'2-5':[],	'3-1':[],	'3-2':[],	'3-3':[],	'3-4':[],	'3-5':[],	'4-1':[],	'4-2':[],	'4-3':[],	'4-4':[],	'4-5':[],	'5-1':[],	'5-2':[],	'5-3':[],	'5-4':[],	'5-5':[],	'6-1':[],	'6-2':[],	'6-3':[],	'6-4':[],	'6-5':[],

}
var board_e  ={
	'1-1':[],	'1-2':[],	'1-3':[],	'1-4':[],	'1-5':[],	'2-1':[],	'2-2':[],	'2-3':[],	'2-4':[],	'2-5':[],	'3-1':[],	'3-2':[],	'3-3':[],	'3-4':[],	'3-5':[],	'4-1':[],	'4-2':[],	'4-3':[],	'4-4':[],	'4-5':[],	'5-1':[],	'5-2':[],	'5-3':[],	'5-4':[],	'5-5':[],	'6-1':[],	'6-2':[],	'6-3':[],	'6-4':[],	'6-5':[],

}



func push_to_stack(effect_data: Dictionary):
	stack.append(effect_data)
	emit_signal("stack_changed")

func pop_from_stack() -> Dictionary:
	if stack.size() > 0:
		return stack.pop_back()
	return {}

func clear_stack():
	stack.clear()
	
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

func on_turn_end_triggers():
	for card in get_all_cards():
		await card.on_turn_end_trigger()
	return null
func end_phase_triggers():
	for card in get_all_cards():
		await card.on_end_phase_trigger()
	return null
	
func on_card_event(event_name: int, source: CardState, target: Array):
	print("card event "+  Card_event.e.keys()[event_name] +" declared from"+source.card_name + " @ "+str(target))
	for c in get_all_cards():
		for eff:Effect_class in c.effects:
			
			match eff.trigger_spec:
				"on_attack":
					if event_name == Card_event.e.ON_ATTACK and c == source:
						_push_trigger(eff, source, target)
				"on_effect_activation":

					if event_name == Card_event.e.ON_EFFECT_ACTIVATED :
						_push_trigger(eff, source, target)
				"on_death":
					if event_name == Card_event.e.ON_DEATH and c == source:
						_push_trigger(eff, source, target)
				"on_destruction":
					if event_name == Card_event.e.ON_DESTRUCTION and c == source:
						_push_trigger(eff, source, target)
				"on_kill":
					if event_name == Card_event.e.ON_KILL and c == source:
						_push_trigger(eff, source, target)
		print(stack)
func _push_trigger(effect: Effect_class, source: CardState, targets: Array):
	var ctx = {
	"game": self,
	"controller": source.controller,
	"source": source,
	"targets": targets
	}
	stack.append({
	"effect": effect,
	"source": source,
	"controller": source.controller,
	"context": ctx
 })
