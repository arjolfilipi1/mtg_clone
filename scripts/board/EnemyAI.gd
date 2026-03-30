extends Node

class_name CardGameAI
#@onready var player_board = $"../PlayerBoard"
var card_played := false
var thinking := false
var game_state
var pl : Player
var difficulty = 1
var attacker:CardState
var defender:CardState
func evaluate_mana_value(produced: Mana, need: Mana) -> int:
	var score := 0
	for color in ["red", "blue", "green", "earth", "white", "black"]:
		score += min(produced.get_color(color), need.get_color(color)) * 2
	score += produced.pay_alt(need)  # generic can be used for anything
	return score
func setup(game_state_ref) -> void:
	game_state = game_state_ref
# Select best mana-producing card, considering its cost
func get_best_mana_card(hand: Array, mana_need: Mana) -> Card:
	var best_card = null
	var best_score := -1

	for cardnode in hand:
		var card = cardnode.state
		var mana_cost = Mana.new()
		var Mana_creation = Mana.new()
		for color in ["generic","red", "blue", "green", "earth", "white", "black"]:
			match color:
				"generic":mana_cost.generic += card.mana_cost["generic"]
				"red":mana_cost.red += card.mana_cost["red"]
				"blue":mana_cost.blue += card.mana_cost["blue"]
				"green":mana_cost.green += card.mana_cost["green"]
				"earth":mana_cost.earth += card.mana_cost["earth"]
				"white":mana_cost.white += card.mana_cost["white"]
				"black":mana_cost.black += card.mana_cost["black"]
		for color in card.mana_creation:
			match color:
				"generic":Mana_creation.generic += 1
				"red":Mana_creation.red += 1
				"blue":Mana_creation.blue += 1
				"green":Mana_creation.green += 1
				"earth":Mana_creation.earth += 1
				"white":Mana_creation.white += 1
				"black":Mana_creation.black += 1
		var adjusted_need := mana_need.subtract(mana_cost)
		var score := evaluate_mana_value(Mana_creation, adjusted_need)
		if score > best_score:
			best_score = score
			best_card = cardnode

	return best_card
func select_mana():
	
	UI_Manager.debug.text += "Enemy is playing card to mana \n"
	pl.mana_selected = true
	#await get_tree().create_timer(1.0).timeout
	var all_nodes = pl.player_hand.get_children()
	if len(all_nodes) == 1:
		pl.mana_selected = true
		TurnManager.finish_mana_selection()
	if all_nodes:
		var need := Mana.new()
		for c in all_nodes:
			var node = c.state
			if not c.is_in_group("card"):
				continue
			for color in ["generic","red", "blue", "green", "earth", "white", "black"]:
				match color:
					"generic":need.generic += node.mana_cost["generic"]
					"red":need.red += node.mana_cost["red"]
					"blue":need.blue += node.mana_cost["blue"]
					"green":need.green += node.mana_cost["green"]
					"earth":need.earth += node.mana_cost["earth"]
					"white":need.white += node.mana_cost["white"]
					"black":need.black += node.mana_cost["black"]
		var best := get_best_mana_card(all_nodes, need)
		var chosen_random_node = all_nodes[randi()% all_nodes.size()]
		if best:
			MovementManager.move_card_to_mana(best, best.state.player_controled, 
				UI_Manager.player_mana_card_nr + 1)
			best.state.to_mana(Game_Manager.gamestate)
			#best.movement.move_to_mana_zone()
		else:
			chosen_random_node.movement.move_to_mana_zone()
			TurnManager.finish_mana_selection()
	else:
		pl.mana_selected = true
		TurnManager.finish_mana_selection()
	pass

func make_decision():
	var possible = generate_possible_action()
	var best_decision = evaluate_actions(possible)
	execute_action(best_decision)
	
func generate_possible_action():
	pass

func evaluate_actions(_possible):
	pass
func execute_action(_action):
	pass
func eval_board():
	var score = 0
	return score
func can_attack():
	for key in Game_Manager.gamestate.board:
		var arr = Game_Manager.gamestate.board[key]
		if len(arr) > 0:
			for card:CardState in arr:
				if card.controller.is_human == false:
					var targets:Array[CardState] = card.can_attack(Game_Manager.gamestate)
					if targets:
						attacker = card
						defender = targets[0]
						TurnManager.current_phase = GameEnums.TurnEnum.ATTACK
					
	
func _process(_delta):
	if not Game_Manager.setup_finished :
		print(pl)
		return 
	if TurnManager.is_selecting_mana and not pl.mana_selected:
		print("enemy playing mana")
		select_mana()
	pass
	if TurnManager.priority == false:
		card_played = false
	if TurnManager.current_phase==GameEnums.TurnEnum.MAIN and TurnManager.priority == false:
		can_attack()
		if TurnManager.current_phase==GameEnums.TurnEnum.MAIN and card_played == false and thinking == false:
			thinking = true
			print("Enemy is thinking of playing card to field")
			UI_Manager.debug.text += "Enemy is playing card to field \n"
			enemy_play_card()
		elif TurnManager.current_phase==GameEnums.TurnEnum.ATTACK:
			attacker.attack(attacker,defender)
			attacker = null
			defender = null

	elif TurnManager.priority == true:
		thinking = false
		card_played = false
func enemy_play_card():
	#await get_tree().create_timer(1.0).timeout  # Small delay
	var area = null
	
	for card:Card in pl.player_hand.get_children():
		if card.state.can_be_payed(Game_Manager.gamestate,card.state.mana_cost) and not card_played:
			var area_list = pl.board.get_children()
			area_list.shuffle()
			for all_area in area_list:
				if all_area.is_in_group("enemy_slots"):

					if all_area.accepts_card(card,Game_Manager.gamestate):
						area = all_area
						break
			if area:
				var rot = area.scew_dict[area.name]
				#card.movement.play_card_to_board(area,180 - rot )
				MovementManager.move_card_to_board(card, area, area.scew_dict.get(area.name, 0) + 180 )
				card.state.play_to_board(area.name, Game_Manager.gamestate)
				area.card_list.append(card)
				print("Enemy is playing card " + card.state.card_name +" to field slot " + area.name)
			else:
				print("Enemy passes. No playable cards.")
			#play_card_to_board(area,card)
			card_played = true
			break

	if not card_played:
		print("Enemy passes. No playable cards.")

	#await get_tree().create_timer(0.5).timeout
	TurnManager.priority = true
