extends Resource
class_name CardState
signal pt_changed(Card)
signal deleted(Card)
# --- Core immutable data (copied from database) ---
var card_data = {}
var card_name: String
var card_range
var mana_cost = {}
var mana_creation = {}
var is_creature: bool
var power: int
var toughness: int
var card_type: String
#if controlled by the player
var player_controled = false
# --- Mutable runtime data ---
enum le {
deck,hand,field,grave,mana
}
var card_location: le = le.deck # hand, field, grave, mana, etc
var pos:String
var tapped: bool = false
var has_summoning_sickness: bool = false
var summoned_on_turn: int = 0
var face_up: bool = false
var controller : Player
var real:bool = true
var effect:Effect_class
var active_buffs:Array = []

func effect_targets():
	if not effect:
		return false
	
	pass

# --- Gameplay logic ---
func can_attack(_turn: int) -> Array:
	var res:Array[Card] =[]
	if card_location == le.field and not has_summoning_sickness:
		#add fake dictionary for ai calcs
		var di = TurnManager.board_slots if real else {}
		for slot:Area2D in get_board_range(di):
			if len( slot.card_list ) > 0:
				if slot.card_list[0].state.can_be_attacked():
					res.append(slot.card_list[0])
				
	return res
func get_board_range(di:Dictionary):
	var res = []
	if not pos:
		return res
	for r in card_range:
		var parts = r.split(".")
		var origin = pos.split("-")
		var name:String
		if player_controled:
			name = str( int(origin[0]) - int(parts[0])) + "-" +str(int(origin[1]) - int(parts[1]) )
		else:
			name = str( int(origin[0]) + int(parts[0])) + "-" +str(int(origin[1]) + int(parts[1]) )
		if name in di:
			res.append(di[name])
		
	return res
func can_be_attacked() -> bool:
	return card_location == le.field

func clone() -> CardState:
	var new_state = CardState.new()
	for property in get_property_list():
		var name = property.name
		new_state.set(name, get(name))
	return new_state

func get_power():
	return card_data.get("power", 0)
func play_to_board(area_name:String,game:GameState,card:Card=null):
	pos = area_name
	if card:
		controller.hand.erase(card)
		controller.battlefield.append(card)
		summoned_on_turn = TurnManager.turn
	controller.board.reset_higlight()
	if card_location == CardState.le.hand:
		if player_controled:
			game.player_hand.erase(self)
		else:
			game.enemy_hand.erase(self)
	card_location = CardState.le.field
	controller.pay_for_card(card)
	face_up = true
	game.board[pos].append(self)
	
func get_toughness():
	return card_data.get("toughness", 0)
#checks if player can play the card
func take_damage(amount:int,_source:Card):
	self.toughness = max(self.toughness - amount , 0)
	if self.toughness ==0:
		emit_signal("deleted",self)
	if real:
		emit_signal("pt_changed",self)

func _remove_expired_buffs():
	print("REMOVING")
	pass

func add_temp_buff(power_to_add:int,toughness_to_add:int,duration:String):
	self.toughness += toughness_to_add
	self.power += power_to_add
	var buff = {"power":power_to_add,"toughness":toughness_to_add,"duration":duration}
	active_buffs.append(buff)
	if real:
		if duration == "until_end_of_turn":
			TurnManager.end_of_turn.connect(_remove_expired_buffs,CONNECT_ONE_SHOT)
		emit_signal("pt_changed",self)
func can_be_payed() -> bool:
	var mana_pool = controller.mana_pool
	var pool = mana_pool.duplicate()
	for color in mana_cost.keys():
		var required = mana_cost[color]
		var available = pool.get(color, 0)
		
		if available >= required:
			# Use same-color mana
			pool[color] -= required
		else:
			# Calculate remaining cost
			var remaining = required - available
			pool[color] = 0
			
			# Calculate how much more we need in other colors (2:1 rate)
			var substitute_needed = remaining * 2
			var substitute_pool = 0
			
			for other_color in pool.keys():
				if other_color == color or other_color == "generic":
					continue
				substitute_pool += pool[other_color]
			
			if substitute_pool < substitute_needed:
				return false  # Not enough alternate mana
			
			# Spend substitute mana
			var to_spend = substitute_needed
			for other_color in pool.keys():
				if other_color == color or other_color == "generic":
					continue
				var usable = min(pool[other_color], to_spend)
				pool[other_color] -= usable
				to_spend -= usable
				if to_spend == 0:
					break
	#not finished calc for spells
	if is_creature:
		return true
	else:
		return false
