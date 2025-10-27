class_name Player

extends Resource
signal mana_changed(Player)
# --- Gameplay State ---
var player_name: String = ""
var life_total: int = 20

signal target_chosen(targets:Array)

var mana_selected = false
var mana_created = false
var player_mana_zone : Node = null
var board : Node = null
var deck : Node = null
var player_hand : Node = null
var player_mana_card_nr = 0
var player_orbs = {
	"generic": [],
	"red": [],
	"blue": [],
	"green": [],
	"earth": [],
	"white": [],
	"black": []}
var mana_pool: Dictionary = {
	"generic": 0,
	"red": 0,
	"blue": 0,
	"green": 0,
	"earth": 0,
	"white": 0,
	"black": 0
}  # e.g., { "G": 1, "R": 2 }

var is_human: bool = false
var priority: bool = false
var did_draw: bool = false

# --- Signals ---
#signal priority_passed()
#signal card_played(card)
#signal life_changed(new_life: int)

func _init(_pn,_pmz,_ph,_b,_d):
	player_name = _pn
	player_mana_zone= _pmz 
	player_hand = _ph
	board = _b
	deck = _d
	mana_changed.connect(mana_match_visual)
	pass
func cost_to_list(raw_list_string):
		# Convert single quotes to double quotes (JSON uses double quotes)
	raw_list_string = raw_list_string.replace("'", '"')

	# Parse the string into an actual array
	var result = JSON.parse_string(raw_list_string)
	return result

func reset_mana():
	TurnManager.debug.text += "reseting mana \n"
	mana_pool = {
	"generic": 0,
	"red": 0,
	"blue": 0,
	"green": 0,
	"earth": 0,
	"white": 0,
	"black": 0
}
	emit_signal("mana_changed",self)
func create_mana():
	print("mana create")
	for color in player_orbs.keys():
		for node in color:
			if is_instance_valid(node):
				node.free()


	for child in player_mana_zone.get_children():
		if child is Sprite2D:
			continue
		if child.is_in_group("card"):
			var list = cost_to_list(child.state.mana_creation)
			for l in list:
				mana_pool[l] += 1
				var orb = player_mana_zone.spawn_mana_orb(l,Vector2(100,125),player_mana_zone)
				orb.z_index = 10
				orb.mana_type = l
				player_orbs[l].append(orb)
	mana_created = true
	TurnManager.priority = !TurnManager.priority 
	TurnManager.finish_mana_creation()
	#current_phase = turn_phases[3]
	pass
#pay for card
func pay_for_card( card) -> void:
	#return 
	TurnManager.debug.text += "Paying for card by "+ player_name +" \n"
	for color in card.state.mana_cost.keys():
		var required = card.state.mana_cost[color]
		var available = mana_pool.get(color, 0)
		
		if available >= required:
			# Use same-color mana
			mana_pool[color] = available - required
		else:
			# Use all available of that color
			var remaining = required - available
			mana_pool[color] = 0
			
			# Pay remaining with other colors at 2:1 rate
			var substitute_needed = remaining * 2
			var to_spend = substitute_needed
			
			for other_color in mana_pool.keys():
				if other_color == color or other_color == "generic":
					continue
				var usable = min(mana_pool[other_color], to_spend)
				mana_pool[other_color] -= usable
				to_spend -= usable
				if to_spend == 0:
					break
	emit_signal("mana_changed",self)

func _request_response_human(game):
	var ui = TurnManager.ui
	ui.show_stack(game.stack)

	# Filter cards that can respond right now (instants, traps, etc.)
	var response_cards = []
	for c in game.player_hand:
		if c.effects : # "quick-play" or "instant" speed
			for eff in c.effects:
				if c.can_respond(game):
					response_cards.append(c)

	if response_cards.is_empty():
		await ui.show_message("No valid responses. Passing priority...")
		return {}

	# Ask the user what to do
	var choice = await ui.ask_choice(["Play a card", "Pass"])
	if choice == "Pass":
		return {}

	# Ask them to pick which card to play
	var selected_card = await ui.select_card_from(response_cards, "Select response card")
	if selected_card == null:
		return {}

	# The effect is not resolved yet; we only push it to stack
	return {
		"type": "play_card",
		"card": selected_card,
		"controller": self
	}
func _request_response_ai(game):
	return {}
func request_response(game: GameState) -> Dictionary:
	# Return a dictionary describing the response or `null` if none
	if is_human:
		return await _request_response_human(game)
	else:
		return _request_response_ai(game)
func mana_match_visual(pl):
	if pl == self:
		TurnManager.debug.text += "Seting mana visuals for "+ player_name +" \n"
		for color in player_orbs.keys():
			while len(player_orbs[color]) > mana_pool[color] :
				var  node = player_orbs[color][-1]
				if is_instance_valid(node):
					player_orbs[color].erase(node)
					node.queue_free()
		player_mana_zone.arrange_mana_orbs_in_circle(Vector2(60,75),30)

# --- Gameplay Flags ---

# --- Public Methods ---
func request_target_selection(possible_targets:Array, target_count:int):
	# UI mode: highlight selectable cards, wait for player to pick
	if is_human:
		var selector = TargetSelector.new()
		player_hand.add_child(selector)
		print(possible_targets,"possible targets")
		selector.start_selection(possible_targets, target_count)
		var selected_targets:Array = await selector.completed 
		
		return selector.selected_targets  # This node will emit "completed" when done
	else:
		var res = []
		while  len(res) < target_count:
			var rand = possible_targets.pop_at( randi() % possible_targets.size())
			res.append(rand)
		return res
func draw(game:GameState,for_turn:bool = true):
	var card := preload("res://scenes/Card.tscn").instantiate()
	var card_id = game.player_deck.pop_at(0) if is_human else game.enemy_deck.pop_at(0)
	if card_id == null:
		print("%s has lost the game!" % player_name)
		return null
	var random_card = TurnManager.game_manager.card_database[card_id]
	card.setup(random_card,self)
	card.state.card_location = CardState.le.hand
	card.state.controller = self
	game.player_hand.append(card.state)
	player_hand.add_child(card)
	TurnManager.game_manager.draw_card(card, deck.position, player_hand.position)
	print("%s draws %s" % [player_name, card.name])
	if for_turn:
		did_draw = true


func take_damage(amount: int):
	life_total -= amount
	emit_signal("life_changed", life_total)
	print("%s takes %d damage (Life: %d)" % [player_name, amount, life_total])
	if life_total <= 0:
		print("%s has lost the game!" % player_name)

func gain_priority():
	priority = true
	print("%s gains priority." % player_name)

func pass_priority():
	priority = false
	emit_signal("priority_passed")
	print("%s passes priority." % player_name)
