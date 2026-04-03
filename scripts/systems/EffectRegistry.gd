extends Node
class_name Effect_Registry

var executors = {}
func _ready():
	register("draw",_draw)
	register("damage",_damage)
	register("buff", _buff)
func register(keyword, func_ref):
	executors[keyword] = func_ref
func _draw(ctx):
	for i in range(ctx.params.get("n",1)):
		await ctx.controller.draw(ctx.game)
func _damage(ctx):
	var target = ctx.targets
	for t in target:
		await t.take_damage(ctx.params.amount , ctx.source ,ctx.game)
func _buff(ctx):
	if len(ctx.targets) == 0:
		print("No targets found")
		return null
	var source = ctx.source
	var tar:Array = ctx.targets
	var params = ctx.params
	for t in tar:
		print("player "+ctx["controller"].player_name +" buffet creature " +t.card_name)
		await t.add_temp_buff(ctx.params.power, ctx.params.toughness, ctx.params.duration,source)
