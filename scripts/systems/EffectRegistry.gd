extends Node
class_name EffectRegistry

var executors = {}
func _ready():
	register("draw",_draw)

func register(keyword, func_ref):
	executors[keyword] = func_ref
func _draw(ctx):
	for i in range(ctx.params.get("n",1)):
		ctx.controler.draw()
