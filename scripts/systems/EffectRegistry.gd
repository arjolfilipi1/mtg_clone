extends Node
class_name Effect_Registry

# ---- Target resolver ----
# Returns an Array[CardState] based on target string + context.
# ctx must contain: game (MTGGameState), source (CardState), controller (Player)
# Some targets also require ctx.filter (Dictionary) for filtered queries.

func resolve_targets(target: String, ctx: Dictionary) -> Array:
	print(ctx.game)
	var game: MTGGameState = ctx.game
	var source: CardState  = ctx.source
	var filter: Dictionary = ctx.get("filter", {})
	var res: Array         = []

	match target:

		# ---- Self / players ----
		"self":
			res = [source]

		"player":
			res = [ctx.controller]

		"enemy":
			for p in TurnManager.players:
				if p != ctx.controller:
					res.append(p)

		# ---- Board creatures ----
		"target_creature":
			for slot in game.board.values():
				for cs in slot:
					if cs.is_creature:
						res.append(cs)

		"target_enemy_creature":
			for slot in game.board.values():
				for cs in slot:
					if cs.is_creature and cs.controller != ctx.controller:
						res.append(cs)

		"target_player_creature":
			for slot in game.board.values():
				for cs in slot:
					if cs.is_creature and cs.controller == ctx.controller:
						res.append(cs)

		"target_all_creature":
			for slot in game.board.values():
				for cs in slot:
					if cs.is_creature:
						res.append(cs)

		"target_card":
			for slot in game.board.values():
				for cs in slot:
					res.append(cs)

		"target_spell":
			for slot in game.board.values():
				for cs in slot:
					if not cs.is_creature:
						res.append(cs)

		# ---- Hand / deck ----
		"target_card_in_hand":
			res = game.player_hand.duplicate()

		"target_card_in_enemy_hand":
			res = game.enemy_hand.duplicate()

		"target_card_in_deck":
			res = game.player_deck.duplicate()

		"target_card_in_enemy_deck":
			res = game.enemy_deck.duplicate()

		# ---- Stack ----
		"target_stack":
			for entry in game.stack:
				res.append(entry)

		# ---- Range ----
		"target_in_range":
			# Returns only board creatures within the source card's attack range
			for slot_list in source.get_board_range(game.board):
				for cs in slot_list:
					if cs.is_creature and cs.controller != source.controller:
						res.append(cs)

		# ---- Filtered targets ----
		"target_creature_of_subtype":
			var subtype: String = filter.get("subtype", "").to_lower()
			for slot in game.board.values():
				for cs in slot:
					if cs.is_creature and cs.card_data.get("subtype","").to_lower() == subtype:
						res.append(cs)

		"target_card_with_total_cost":
			var cost_value: int = filter.get("value", 0)
			for slot in game.board.values():
				for cs in slot:
					var total = 0
					for v in cs.mana_cost.values():
						total += v
					if total == cost_value:
						res.append(cs)

		"target_creature_with_total_cost":
			var cost_value: int = filter.get("value", 0)
			for slot in game.board.values():
				for cs in slot:
					if not cs.is_creature:
						continue
					var total = 0
					for v in cs.mana_cost.values():
						total += v
					if total == cost_value:
						res.append(cs)

		"target_card_with_only_mana_cost_of":
			var color: String = filter.get("color", "")
			for slot in game.board.values():
				for cs in slot:
					var has_only = true
					for c in cs.mana_cost.keys():
						if c != color and c != "generic" and cs.mana_cost[c] > 0:
							has_only = false
							break
					if has_only:
						res.append(cs)

		"target_creature_with_only_mana_cost_of":
			var color: String = filter.get("color", "")
			for slot in game.board.values():
				for cs in slot:
					if not cs.is_creature:
						continue
					var has_only = true
					for c in cs.mana_cost.keys():
						if c != color and c != "generic" and cs.mana_cost[c] > 0:
							has_only = false
							break
					if has_only:
						res.append(cs)

		"none":
			res = []

		_:
			push_error("EffectRegistry: unknown target type '%s'" % target)

	return res
# ---- Action executors ----
# Each takes (action: Dictionary, ctx: Dictionary)
# ctx contains: game, source, controller, targets (resolved for this action)

var executors: Dictionary = {}

func _ready() -> void:
	executors = {
		"damage":         _damage,
		"buff":           _buff,
		"draw":           _draw,
		"destroy":        _destroy,
		"send_to_grave":  _send_to_grave,
		"gain_control":   _gain_control,
		"copy_effect":    _copy_effect,
		"duplicate":      _duplicate,
		"change_effect_to": _change_effect_to,
	}


# ---- damage ----
func _damage(action: Dictionary, ctx: Dictionary) -> void:
	var amount: int = action.get("amount", 0)
	for t in ctx.targets:
		if t is CardState:
			await t.take_damage(amount, ctx.source, ctx.game)
		elif t is Player:
			t.take_damage(amount)


# ---- buff ----
func _buff(action: Dictionary, ctx: Dictionary) -> void:
	var power:      int    = action.get("power", 0)
	var toughness:  int    = action.get("toughness", 0)
	var duration:   String = action.get("duration", "instant")
	for t in ctx.targets:
		if t is CardState:
			await t.add_temp_buff(power, toughness, duration, ctx.source)


# ---- draw ----
func _draw(action: Dictionary, ctx: Dictionary) -> void:
	var amount: int = action.get("amount", 1)
	for i in range(amount):
		await ctx.controller.draw(ctx.game)


# ---- destroy ----
# Destroy triggers on_destruction — use this for effects that say "destroy"
func _destroy(action: Dictionary, ctx: Dictionary) -> void:
	for t in ctx.targets:
		if t is CardState:
			await ctx.game.on_card_event(Card_event.e.ON_DESTRUCTION, t, [])
			t.destroy_card(ctx.game)


# ---- send_to_grave ----
# Sends directly to grave without triggering on_destruction (e.g. exile-style removal)
func _send_to_grave(action: Dictionary, ctx: Dictionary) -> void:
	for t in ctx.targets:
		if t is CardState:
			t.destroy_card(ctx.game)


# ---- gain_control ----
func _gain_control(action: Dictionary, ctx: Dictionary) -> void:
	for t in ctx.targets:
		if not t is CardState:
			continue
		var old_controller: Player = t.controller
		t.controller = ctx.controller
		t.player_controled = ctx.controller.is_human
		# Move in gamestate boards
		if t.card_location == GameEnums.CardZone.FIELD:
			ctx.game.board[t.pos].erase(t)
			if not ctx.game.board.has(t.pos):
				ctx.game.board[t.pos] = []
			ctx.game.board[t.pos].append(t)
		# Update visual controller reference if card node exists
		if t.card_node and is_instance_valid(t.card_node):
			t.card_node.movement.play_card_to_board(t.card_node.board_pos, 0)


# ---- copy_effect ----
# Copies all effects from target card onto the source card for this turn
func _copy_effect(action: Dictionary, ctx: Dictionary) -> void:
	for t in ctx.targets:
		if not t is CardState:
			continue
		for eff in t.effects:
			var copy := Effect_class.new()
			copy.actions       = eff.actions.duplicate(true)
			copy.trigger_spec  = eff.trigger_spec
			copy.target_count  = eff.target_count
			copy.speed         = eff.speed
			copy.mandatory     = eff.mandatory
			copy.mana_cost     = eff.mana_cost.duplicate()
			copy.once_per_turn = "soft"
			copy.description   = "[Copy] " + eff.description
			copy.used_this_turn = false
			ctx.source.effects.append(copy)
			# Remove at end of turn
			TurnManager.end_of_turn.connect(
				func(): ctx.source.effects.erase(copy),
				CONNECT_ONE_SHOT
			)


# ---- duplicate ----
# Puts a copy of the source card into the controller's hand
func _duplicate(action: Dictionary, ctx: Dictionary) -> void:
	var card_scene = load("res://scenes/Card.tscn").instantiate()
	card_scene.setup(ctx.source.card_data, ctx.controller)
	card_scene.state.card_location = GameEnums.CardZone.HAND
	if ctx.controller.is_human:
		ctx.game.player_hand.append(card_scene.state)
	else:
		ctx.game.enemy_hand.append(card_scene.state)
	ctx.controller.player_hand.add_child(card_scene)
	Game_Manager.draw_card(card_scene, Game_Manager.initialPosition,
		ctx.controller.player_hand.global_position)


# ---- change_effect_to ----
# Replaces all effects on a target card with the source card's effects
func _change_effect_to(action: Dictionary, ctx: Dictionary) -> void:
	for t in ctx.targets:
		if not t is CardState:
			continue
		t.effects.clear()
		for eff in ctx.source.effects:
			var copy := Effect_class.new()
			copy.actions       = eff.actions.duplicate(true)
			copy.trigger_spec  = eff.trigger_spec
			copy.target_count  = eff.target_count
			copy.speed         = eff.speed
			copy.mandatory     = eff.mandatory
			copy.mana_cost     = eff.mana_cost.duplicate()
			copy.once_per_turn = eff.once_per_turn
			copy.description   = eff.description
			t.effects.append(copy)
