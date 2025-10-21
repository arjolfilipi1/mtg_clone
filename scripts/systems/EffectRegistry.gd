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
		ctx.controler.draw()
func _damage(ctx):
	var target = ctx.targets[0]
	target.state.take_damage(ctx.params.amount,ctx.source)
func _buff(ctx):
	
	if len(ctx.targets) == 0:
		print("No targets found")
		return null
	var t:CardState = ctx.targets[0]
	var params = ctx.params
	print("player "+ctx["controller"].player_name +" buffet creature " +t.card_name)
	t.add_temp_buff(ctx.params.power, ctx.params.toughtness, ctx.params.duration)
