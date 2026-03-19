extends RefCounted
class_name GameRules

# Pure logic functions - no side effects, just checks
static func can_play_card(game: GameState, card: CardState, player: Player) -> bool:
	if player != game.active_player:
		return false
	
	if game.current_phase != GameState.Phase.MAIN:
		return false
	
	if card.zone != CardState.Zone.HAND:
		return false
	
	if card.controller != player:
		return false
	
	return can_pay_mana_cost(game, card, player)

static func can_pay_mana_cost(game: GameState, card: CardState, player: Player) -> bool:
	var mana_pool = _get_mana_pool(game, player)
	return _can_pay_cost(mana_pool, card.mana_cost)

static func can_attack(game: GameState, attacker: CardState, target) -> bool:
	# target can be CardState or "player"
	if not attacker.is_creature:
		return false
	
	if attacker.zone != CardState.Zone.FIELD:
		return false
	
	if attacker.has_summoning_sickness:
		return false
	
	if attacker.tapped:
		return false
	
	if game.current_phase != GameState.Phase.ATTACK_DECLARE:
		return false
	
	if attacker.controller != game.active_player:
		return false
	
	# Check if target is in range
	return is_in_attack_range(game, attacker, target)

static func is_in_attack_range(game: GameState, attacker: CardState, target) -> bool:
	if target is CardState:
		return _is_creature_in_range(attacker, target, game)
	else:  # attacking player directly
		return _is_player_in_range(attacker, game)

static func _is_creature_in_range(attacker: CardState, defender: CardState, game: GameState) -> bool:
	var attacker_pos = attacker.board_position
	var defender_pos = defender.board_position
	
	for range_str in attacker.attack_range:
		var offset = _parse_range_offset(range_str)
		var target_pos = _apply_offset(attacker_pos, offset, attacker.controller.is_human)
		if target_pos == defender_pos:
			return true
	return false

static func _is_player_in_range(attacker: CardState, game: GameState) -> bool:
	# Players are at positions "0-1" (front) and "0-6" (back) maybe?
	# Define your own logic
	return true

static func get_valid_attack_targets(game: GameState, attacker: CardState) -> Array:
	var targets = []
	
	# Check creatures in range
	for slot_name in game.board.keys():
		for defender in game.board[slot_name]:
			if defender.controller != attacker.controller and _is_creature_in_range(attacker, defender, game):
				targets.append(defender)
	
	# Check if can attack player directly
	#if _can_attack_player_directly(game, attacker):
		#targets.append("player")
	
	return targets

static func can_activate_effect(game: GameState, card: CardState, effect_index: int) -> bool:
	var effect = card.effects[effect_index]
	
	# Check timing
	if not _is_effect_timing_valid(game, effect):
		return false
	
	# Check mana cost
	if not _can_pay_cost(_get_mana_pool(game, card.controller), effect.mana_cost):
		return false
	
	# Check if effect has valid targets
	var targets = get_valid_targets_for_effect(game, card, effect)
	if effect.requires_target and targets.is_empty():
		return false
	
	return true

static func get_valid_targets_for_effect(game: GameState, source: CardState, effect: Effect_class) -> Array:
	var targets = []
	
	match effect.target_type:
		Effect_class.TargetType.SELF:
			targets = [source]
		Effect_class.TargetType.SINGLE_CREATURE:
			for slot in game.board.values():
				for card in slot:
					#if card.is_creature and _is_valid_target_by_relation(effect, source, card):
					if card.is_creature :
						targets.append(card)
		Effect_class.TargetType.ALL_CREATURES:
			for slot in game.board.values():
				for card in slot:
					if card.is_creature:
						targets.append(card)
		Effect_class.TargetType.PLAYER:
			targets = [source.controller]
		Effect_class.TargetType.OPPONENT:
			targets = [_get_opponent(game, source.controller)]
	
	return targets
static func _get_opponent (game: GameState, controller: Player) -> Player:
	if controller == game.player1:
		return game.player2
	elif controller == game.player2:
		return game.player1
	else:
		return null
# Private helper functions
static func _get_mana_pool(game: GameState, player: Player) -> Dictionary:
	var pool = {
		"generic": 0, "red": 0, "blue": 0, "green": 0, 
		"earth": 0, "white": 0, "black": 0
	}
	
	var mana_zone = player.mana_zone if player.is_human else game.opponent_mana
	for card in mana_zone:
		for color in card.mana_production:
			pool[color] += 1
	
	return pool

static func _can_pay_cost(pool: Dictionary, cost: Dictionary) -> bool:
	var temp_pool = pool.duplicate()
	
	for color in cost.keys():
		var required = cost[color]
		if temp_pool[color] >= required:
			temp_pool[color] -= required
		else:
			# Can use generic mana for colored costs at 2:1 rate
			var remaining = required - temp_pool[color]
			temp_pool[color] = 0
			
			if temp_pool["generic"] >= remaining * 2:
				temp_pool["generic"] -= remaining * 2
			else:
				return false
	return true

static func _is_effect_timing_valid(game: GameState, effect: Effect_class) -> bool:
	match effect.speed:
		Effect_class.Speed.SORCERY:
			return game.current_phase == GameState.Phase.MAIN and game.active_player == effect.controller
		Effect_class.Speed.INSTANT:
			return true  # Can be played anytime player has priority
		Effect_class.Speed.MANA_ABILITY:
			return game.current_phase == GameState.Phase.MANA_CREATE
	return false

static func _parse_range_offset(range_str: String) -> Vector2i:
	var parts = range_str.split(".")
	return Vector2i(int(parts[0]), int(parts[1]))

static func _apply_offset(pos: String, offset: Vector2i, is_player: bool) -> String:
	var parts = pos.split("-")
	var x = int(parts[0])
	var y = int(parts[1])
	
	if is_player:
		x -= offset.x
		y -= offset.y
	else:
		x += offset.x
		y += offset.y
	
	return "%d-%d" % [x, y]
