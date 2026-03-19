extends Resource
class_name GameState

enum Phase { 
	DRAW, 
	MANA_SELECT, 
	MANA_CREATE, 
	MAIN, 
	ATTACK_DECLARE,
	BLOCK_DECLARE,
	DAMAGE,
	END 
}
var current_phase: Phase = Phase.DRAW
var turn_number: int = 1
var active_player: Player  # Who has priority
var turn_player: Player    # Whose turn it is
var priority_passes: int = 0
# Players
var player1: Player
var player2: Player
# Zones (all CardState references)
var board: Dictionary = {'1-1':[],	'1-2':[],	'1-3':[],	'1-4':[],	'1-5':[],	'2-1':[],	'2-2':[],	'2-3':[],	'2-4':[],	'2-5':[],	'3-1':[],	'3-2':[],	'3-3':[],	'3-4':[],	'3-5':[],	'4-1':[],	'4-2':[],	'4-3':[],	'4-4':[],	'4-5':[],	'5-1':[],	'5-2':[],	'5-3':[],	'5-4':[],	'5-5':[],	'6-1':[],	'6-2':[],	'6-3':[],	'6-4':[],	'6-5':[],}  # Key: slot name, Value: Array[CardState]
var stack: Array[StackItem] = []


var player_hand:Array[CardState]
var player_deck:Array[int] = []
var player_grave:Array[CardState]
var player_mana:Array[CardState]
var player_exile: Array[CardState]

var enemy_hand:Array[CardState]
var enemy_deck:Array[int] = []
var enemy_grave:Array[CardState]
var enemy_mana:Array[CardState]
var opponent_exile: Array[CardState]

# Combat state
var attackers: Dictionary = {}  # Key: attacker CardState, Value: target (CardState or "player")
var blockers: Dictionary = {}   # Key: blocker CardState, Value: attacker CardState
var combat_damage_queue: Array[Dictionary] = []

# Targeting state
var targeting_card: CardState = null
var targeting_mode: TargetingMode = TargetingMode.NONE
var valid_targets: Array[CardState] = []
var pending_target_count: int = 0
var pending_effect: Effect_class = null

# History for AI/undo/replay
var action_history: Array[GameAction] = []
var current_snapshot: Dictionary = {}

# Signals
signal phase_changed(old_phase: Phase, new_phase: Phase)
signal turn_changed(new_turn_player: Player)
signal priority_changed(new_priority_player: Player)
signal stack_changed(stack: Array)
signal card_moved(card: CardState, from_zone: String, to_zone: String)
signal life_changed(player: Player, old_life: int, new_life: int)
signal game_over(winner: Player)


var board_e  ={
	'1-1':[],	'1-2':[],	'1-3':[],	'1-4':[],	'1-5':[],	'2-1':[],	'2-2':[],	'2-3':[],	'2-4':[],	'2-5':[],	'3-1':[],	'3-2':[],	'3-3':[],	'3-4':[],	'3-5':[],	'4-1':[],	'4-2':[],	'4-3':[],	'4-4':[],	'4-5':[],	'5-1':[],	'5-2':[],	'5-3':[],	'5-4':[],	'5-5':[],	'6-1':[],	'6-2':[],	'6-3':[],	'6-4':[],	'6-5':[],

}
enum TargetingMode {
	NONE,
	ATTACK,
	BLOCK,
	EFFECT_SINGLE,
	EFFECT_MULTIPLE
}

class StackItem:
	var effect: Effect_class
	var source_card: CardState
	var controller: Player
	var targets: Array[CardState]
	var context: Dictionary
	
	func _init(e: Effect_class, source: CardState, ctrl: Player, targs: Array = [], ctx: Dictionary = {}):
		effect = e
		source_card = source
		controller = ctrl
		targets = targs
		context = ctx

class GameAction:
	var action_type: String  # "play_card", "attack", "activate_effect", etc.
	var player: Player
	var card: CardState
	var targets: Array
	var timestamp: int
	var snapshot_before: Dictionary


func push_to_stack(effect_data: Dictionary):
	if effect_data != {}:
		stack.append(effect_data)
		emit_signal("stack_changed")

func pop_from_stack() -> Dictionary:
	if stack.size() > 0:
		return stack.pop_at(-1)
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
	print("card event "+  Card_event.e.keys()[event_name] +" declared from "+source.card_name + " @ "+str(target))
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
func _push_trigger(effect: Effect_class, source: CardState, targets: Array):
	var ctx = {
	"game": self,
	"controller": source.controller,
	"source": source,
	"targets": targets
	}
	print("pushing to stack "+source.card_name+" effect:" + effect.spec)
	stack.append({
	"effect": effect,
	"source": source,
	"controller": source.controller,
	"context": ctx
 })
