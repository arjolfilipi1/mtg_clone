extends Resource
class_name CardState
signal pt_changed(CardState)
signal deleted(CardState)
signal moved_to_mana(CardState)
signal activated_effect(Effect_class)
signal flip(bool)
signal attack_signal(attacker:CardState, defender:CardState)
# --- Core immutable data (copied from database) ---
var card_data:Dictionary
var card_name: String
var card_range:Array
var mana_cost :Dictionary
var mana_creation :Array
var is_creature: bool
var power: int
var toughness: int
var card_type : GameEnums.CardType
#if controlled by the player
var player_controled = false
# --- Mutable runtime data ---
var card_location: GameEnums.CardZone = GameEnums.CardZone.DECK
#board position name, 6x5 grid 
var pos:String
var tapped: bool = false
var has_summoning_sickness: bool = false
var summoned_on_turn: int = 0
var face_up: bool = false
var controller : Player
var image : String
#real card for the game, not real used for enemy ai 
var real:bool = true
var effects:Array[Effect_class] = []
var active_buffs:Array = []
var card_node:Card

#signal that the card is attacking
func attack(attacker:CardState, defender:CardState):
	emit_signal("attack_signal",attacker,defender)

#setup and store data from the json database
# Setup with type-safe enums
func flip_up():
	if not face_up:
		face_up = true
		emit_signal("flip",true)
func setup(data: Dictionary):
	card_data = data
	face_up = controller.is_human
	card_name = card_data['name']
	card_range = card_data['range'] if card_data['range'] != null else []
	power = card_data['power']
	toughness = card_data['toughness']
	image = card_data['image']
	# Convert string type to enum
	match card_data['type'].to_lower():
		"creature": card_type = GameEnums.CardType.CREATURE
		"spell": card_type = GameEnums.CardType.SPELL
		"enchantment": card_type = GameEnums.CardType.ENCHANTMENT
		"artifact": card_type = GameEnums.CardType.ARTIFACT
		_ : card_type = GameEnums.CardType.CREATURE
	
	is_creature = card_type == GameEnums.CardType.CREATURE
	mana_cost = card_data['mana_cost']
	mana_creation = card_data['Mana_creation']
	
	var effects_spec = card_data['effects']
	if effects_spec:
		_load_effects_from_data(effects_spec)

func destroy_card(game:MTGGameState):
	if card_location == GameEnums.CardZone.HAND:
		if controller.is_human:
			game.player_hand.erase(self)
			game.player_grave.append(self)
		else:
			game.enemy_hand.erase(self)
			game.enemy_grave.append(self)
	elif card_location == GameEnums.CardZone.FIELD:
		game.board[pos].erase(self)
	if controller.is_human:
		game.player_grave.append(self)
	else:
		game.enemy_grave.append(self)
	card_location = GameEnums.CardZone.GRAVEYARD
	
	pos = ""
	emit_signal("deleted",self)
	print(card_name +" was destoyed")
	
#function to get effect targets
func effect_targets(gs:MTGGameState, eff:Effect_class):
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
func apply_effect(effect:Effect_class,game:MTGGameState = Game_Manager.gamestate):
	if real:
		TurnManager.waiting_for_input = true

	var ctx := {
		"game":       game,
		"controller": controller,
		"source":     self,
	}

	# For targeted effects, resolve candidates and ask player if needed
	# (EffectRunner handles per-action targeting, so here we just push to stack)
	activated_effect.emit(effect)
	var se = StackEntry.new( effect,self,controller)
	#game.push(se)
	game.push_to_stack({
		"effect":     effect,
		"source":     self,
		"controller": controller,
		"context":    ctx,
	})

	await game.on_card_event(
		Card_event.e.ON_EFFECT_ACTIVATED, self, []
	)
	if real:
		TurnManager.waiting_for_input = false

	if card_type == GameEnums.CardType.SPELL:
		destroy_card(game)


func can_respond(game:MTGGameState,index:int)-> bool:
	var eff = effects[index]
	var last_stack = game.stack[-1]
	if eff.speed > 1 and eff != last_stack.effect and eff.speed >= last_stack.effect.speed :
		if can_activate_effect(game,eff) and effect_targets(game,eff):
			return true
	
	return false
func _load_effects_from_data(effects_spec: Array) -> void:
	for effect_spec in effects_spec:
		var e := Effect_class.new()
		e.actions       = effect_spec.get("actions", [])
		e.trigger_spec  = effect_spec.get("trigger", "")
		e.target_count  = effect_spec.get("target_count", 1)
		e.speed         = effect_spec.get("speed", 1)
		e.mandatory     = effect_spec.get("mandatory", false)
		e.once_per_turn = effect_spec.get("once_per_turn", "soft")
		e.description   = effect_spec.get("description", "")
		if effect_spec.has("mana_cost") and effect_spec.mana_cost is Dictionary:
			e.mana_cost = effect_spec.mana_cost
		effects.append(e)

func can_move(game:MTGGameState) -> Array:
	if card_location != GameEnums.CardZone.FIELD or not pos:
		return []
	var res:Array = []
	var origin = pos.split("-")
	var x = int(origin[0])
	var y = int(origin[1])
	var adj:Array = [str(x-1)+"-"+str(y),str(x)+"-"+str(y-1),str(x+1)+"-"+str(y),str(x)+"-"+str(y+1)]
	for a in adj:
		if a in game.board:
			if len(game.board[a]) == 0:
				res.append(a)
	return res
#check if effect can be activated, will be added to later
func can_activate_effect(game:MTGGameState,effect:Effect_class = null) ->Array[Effect_class]:
	var res: Array[Effect_class] = []
	for eff in effects:
		if effect != null and eff != effect:
			continue
		if eff.used_this_turn and eff.once_per_turn != "":
			continue
		if not can_be_payed(game, eff.mana_cost):
			continue
		match eff.trigger_spec:
			"true":
				res.append(eff)
			"selected_on_hand":
				if card_location == GameEnums.CardZone.HAND:
					res.append(eff)
			"on_stack_buff":
				print(game.stack.size(),game.stack[-1].effect.description if len(game.stack)> 0 else "-" )
				if game.stack.size() > 0 and "buff" in game.stack[-1].effect.description:
					res.append(eff)
	return res

# --- Gameplay logic ---
func can_attack(game:MTGGameState) -> Array:
	
	var res:Array[CardState] =[]
	if  not is_creature:
		return res
	if card_location == GameEnums.CardZone.FIELD and not has_summoning_sickness:
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

		var origin = pos.split("-")
		var name:String
		if player_controled:
			name = str( int(origin[0]) - int(r[0])) + "-" +str(int(origin[1]) - int(r[1]) )
		else:
			name = str( int(origin[0]) + int(r[0])) + "-" +str(int(origin[1]) + int(r[1]) )
		if name in di:
			res.append(di[name])
		
	return res

func can_be_attacked() -> bool:
	return card_location == GameEnums.CardZone.FIELD

func on_end_phase_trigger():
	if effects.size() > 0:
		for eff in effects:
			if eff and eff.trigger_spec == "on_end_phase":
				print("Playing card with on_end_phase effect: ", eff.spec)
				apply_effect(eff)
			elif eff and eff.trigger_spec == "on_end_phase_on_field" and card_location == GameEnums.CardZone.FIELD:
				print("Playing card with on_end_phase effect: ", eff.spec)
				await apply_effect(eff)
func on_turn_end_trigger():
	if effects.size() > 0:
		for eff in effects:
			if eff and eff.trigger_spec == "on_turn_end_on_field" and card_location == GameEnums.CardZone.FIELD:
				print("Playing "+ card_name +" with on_turn_end effect: ", eff.spec)
				await apply_effect(eff)
	return null


func on_summon():
	pass

func get_power():
	return card_data.get("power", 0)

func play_to_board(area_name:String,game:MTGGameState):
	if is_creature:
		pos = area_name
		
		summoned_on_turn = game.turn
		controller.board.reset_higlight()
		if card_location == GameEnums.CardZone.HAND:
			if player_controled:
				game.player_hand.erase(self)
				game.board[area_name].append(self)
			else:
				game.board_e[area_name].append(self)
				game.enemy_hand.erase(self)
		card_location = GameEnums.CardZone.FIELD
		controller.pay_for_card(self)
		flip_up()
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


func take_damage(amount:int,_source:CardState,game:MTGGameState):
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
	
func add_temp_buff(power_to_add:int,toughness_to_add:int,duration:String,_source):
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
func to_mana(game:MTGGameState):

	if controller.is_human:
		game.player_hand.erase(self)
		game.player_mana.append(self)
	else:
		game.enemy_hand.erase(self)
		game.enemy_mana.append(self)
	card_location = GameEnums.CardZone.MANA
	moved_to_mana.emit(self)
#checks if player can play the card
func can_be_payed(_game:MTGGameState,cost) -> bool:
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
