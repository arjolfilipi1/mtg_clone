extends Resource
class_name CardState
signal pt_changed(CardState)
signal deleted(CardState)
signal activated_effect(Effect_class)
signal attack_signal(attacker:CardState, defender:CardState)
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
#board position name, 6x5 grid 
var pos:String
var tapped: bool = false
var has_summoning_sickness: bool = false
var summoned_on_turn: int = 0
var face_up: bool = false
var controller : Player
#real card for the game, not real used for enemy ai 
var real:bool = true
var effects:Array[Effect_class] = []
var active_buffs:Array = []
var card_node:Card

#signal that the card is attacking
func attack(attacker:CardState, defender:CardState):
	emit_signal("attack_signal",attacker,defender)

#setup and store data from the json database
func setup(data):
	card_data = data
	if controller.is_human:
		face_up = true
	card_name = card_data['name']
	card_range = card_data['range']
	power = card_data['power']
	toughness = card_data['toughness']
	card_type = card_data['type']
	mana_cost = card_data['mana_cost']
	is_creature = card_data['type'] == "Creature"
	mana_creation = card_data['Mana_creation']
	var effects_spec = card_data['effects']
	if effects_spec:
		for effect_spec in effects_spec:
			var e = Effect_class.new()
			e.spec = effect_spec.spec
			e.target_count = effect_spec.target_count
			e.target_spec = effect_spec.target_spec
			e.trigger_spec = effect_spec.trigger_spec
			e.mandatory = effect_spec.mandatory
			e.targets = effect_spec.targets
			if effect_spec.mana_cost:
				e.mana_cost = effect_spec.mana_cost
			else:
				e.mana_cost = {}
			effects.append(e)

func destroy_card(game:GameState):
	if card_location == 1:
		if controller.is_human:
			game.player_hand.erase(self)
			game.player_grave.append(self)
		else:
			game.enemy_hand.erase(self)
			game.enemy_grave.append(self)
	elif card_location == 2:
		game.board[pos].erase(self)
		if controller.is_human:
			game.player_grave.append(self)
		else:
			game.enemy_grave.append(self)
	card_location = le.grave
	
	pos = ""
	emit_signal("deleted",self)
	print(card_name +" was destoyed")
	
#function to get effect targets
func effect_targets(gs:GameState, eff:Effect_class):
	if eff.target_spec == "self":
		return [self]
	var res:Array = []
	if not eff:
		return []
	if eff.target_spec in ["target_creature","target_all_creature","target_card","target_spell","target_enemy_creature","target_player_creature"]:
		for key in gs.board.keys():
			var arr = gs.board[key]
			if len(arr) > 0:
				for card in arr:
					if eff.target_spec in ["target_creature","target_all_creature"] and card.is_creature:
						res.append(card)
					elif eff.target_spec == "target_card":
						res.append(card)
					elif eff.target_spec in ["target_spell"] and card.is_creature == false:
						res.append(card)
					elif eff.target_spec in ["target_enemy_creature"] and card.is_creature and card.controller.is_human != controller.is_human:
						res.append(card)
					elif eff.target_spec in ["target_player_creature"] and card.is_creature and card.controller.is_human == controller.is_human:
						res.append(card)

	return res

#runs the effect
func apply_effect(effect:Effect_class):
	if real:
		TurnManager.waiting_for_input = true
	if effect:
		var game = TurnManager
		var ctx = {
		"game": game.game_manager.gamestate,
		"controller": controller,
		"source": self,
		"targets": effect_targets(game.game_manager.gamestate,effect)
	}
		if effect.targets and effect.target_spec not in ["self","none"] and len(ctx.targets) > effect.target_count:
		# Pause and ask the player to choose
			var possible_targets = ctx.targets
			var chosen_targets = await controller.request_target_selection(possible_targets, effect.target_count)
			print(chosen_targets,"ct")
			if not chosen_targets or chosen_targets.is_empty():
				print("Effect canceled - no targets chosen")
				return
			ctx.targets = chosen_targets
		await EffectRunner.apply_effect(effect,ctx)
		TurnManager.waiting_for_input = false
		if card_type == "Spell":
			destroy_card(game.game_manager.gamestate)

#check if effect can be activated, will be added to later
func can_activate_effect(game:GameState) ->Array[Effect_class]:
	var res :Array[Effect_class] = []
	if effects:
		for eff in effects:
			if eff.trigger_spec == "selected_on_hand" :
				print(can_be_payed(game,eff.mana_cost))
				if card_location == le.hand and can_be_payed(game,eff.mana_cost):
					res.append(eff)
	return res
# --- Gameplay logic ---
func can_attack(game:GameState) -> Array:
	
	var res:Array[CardState] =[]
	if  not is_creature:
		return res
	if card_location == le.field and not has_summoning_sickness:
		#add fake dictionary for ai calcs
		var di =  game.board
		for slot in get_board_range(di):
			if len( slot ) > 0:
				if slot[0].can_be_attacked() and slot[0].controller != controller:
					res.append(slot[0])
				
	return res

#cards hace a range expressed as a list of values "1.0" etc
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

func on_end_phase_trigger():
	if effects.size() > 0:
		for eff in effects:
			if eff and eff.trigger_spec == "on_end_phase":
				print("Playing card with on_end_phase effect: ", eff.spec)
				apply_effect(eff)
			elif eff and eff.trigger_spec == "on_end_phase_on_field" and card_location == le.field:
				print("Playing card with on_end_phase effect: ", eff.spec)
				apply_effect(eff)
func on_turn_end_trigger():
	if effects.size() > 0:
		for eff in effects:
			if eff and eff.trigger_spec == "on_turn_end_on_field" and card_location == le.field:
				print("Playing "+ card_name +" with on_turn_end effect: ", eff.spec)
				await apply_effect(eff)
	return null


func on_summon():
	pass

func get_power():
	return card_data.get("power", 0)

func play_to_board(area_name:String,game:GameState,card:Card=null):
	if is_creature:
		pos = area_name
		if controller.is_human:
			game.player_hand.erase(card.state)
		else:
			game.enemy_hand.erase(card.state)
		summoned_on_turn = game.turn
		controller.board.reset_higlight()
		if card_location == le.hand:
			if player_controled:
				game.player_hand.erase(self)
			else:
				game.enemy_hand.erase(self)
		card_location = le.field
		controller.pay_for_card(card)
		face_up = true
		game.board[pos].append(self)
		on_summon()
	if effects.size() > 0:
		print("has effect")
		for eff in effects:
			if eff and eff.trigger_spec == "on_play":
				print("Playing card with on_play effect: ", eff.spec)
				await apply_effect(eff)
	return true

func get_toughness():
	return card_data.get("toughness", 0)


func take_damage(amount:int,_source:CardState,game:GameState):
	self.toughness = max(self.toughness - amount , 0)
	if self.toughness ==0:
		destroy_card(game)
		emit_signal("deleted",self)
	if real:
		emit_signal("pt_changed",self)

func _remove_expired_buffs():
	active_buffs = active_buffs.filter(func(b): return b.duration != "until_end_of_turn")
	_recalculate_stats()
	
func _recalculate_stats():
	var total_power = card_data.get("power", 0)
	var total_toughness =  card_data.get("toughness", 0)
	for b in active_buffs:
		total_power += b.power
		total_toughness += b.toughness
	power = total_power
	toughness = total_toughness
	emit_signal("pt_changed",self)
	
func add_temp_buff(power_to_add:int,toughness_to_add:int,duration:String):
	self.toughness += toughness_to_add
	self.power += power_to_add
	var buff = {"power":power_to_add,"toughness":toughness_to_add,"duration":duration}
	active_buffs.append(buff)
	if real:
		if duration == "until_end_of_turn":
			if not TurnManager.end_of_turn.is_connected(_remove_expired_buffs):
				TurnManager.end_of_turn.connect(_remove_expired_buffs, CONNECT_ONE_SHOT)
		emit_signal("pt_changed",self)

#send card to mana zone, we are using card as resource 
func to_mana(game:GameState):

	if controller.is_human:
		game.player_hand.erase(self)
		game.player_mana.append(self)
	else:
		game.enemy_hand.erase(self)
		game.enemy_mana.append(self)
	card_location = le.mana

#checks if player can play the card
func can_be_payed(game:GameState,cost) -> bool:
	var mana_pool = controller.mana_pool
	var pool = mana_pool.duplicate()
	for color in cost.keys():
		var required = cost[color]
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
	return true
