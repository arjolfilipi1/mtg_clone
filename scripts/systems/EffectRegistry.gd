extends Node
class_name Effect_Registry

var executors = {}
func _ready():
	register("draw",_draw)
	register("damage",_damage)
func register(keyword, func_ref):
	executors[keyword] = func_ref
func _draw(ctx):
	for i in range(ctx.params.get("n",1)):
		ctx.controler.draw()
func _damage(ctx):
	var target = ctx.targets[0]
	target.state.take_damage(ctx.params.amount,ctx.source)
