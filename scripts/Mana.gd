class_name Mana

extends Resource

var generic := 0
var red := 0
var blue := 0
var green := 0
var earth := 0
var white := 0
var black := 0

func total() -> int:
	return generic + red + blue + green + earth + white + black

func to_dict() -> Dictionary:
	return {
		"generic": generic,
		"red": red,
		"blue": blue,
		"green": green,
		"earth": earth,
		"white": white,
		"black": black
	}
static func keys() -> Array:
		return ["generic", "red", "blue", "green", "earth", "white", "black"]
func get_color(color: String) -> int:
	return self.get(color)

func clone() -> Mana:
	var copy := Mana.new()
	for color in to_dict().keys():
		copy.set(color, get(color))
	return copy
func pay_alt(other: Mana)-> int:
	var pos := 0
	for color in to_dict().keys():
		var step := 0
		match color:
			"generic":step += max(generic - other.generic,0)
			"red":step += max(red - other.red,0)
			"blue":step += max(blue - other.blue,0)
			"green":step += max(green - other.green,0)
			"earth":step += max(earth - other.earth,0)
			"white":step += max(white - other.white,0)
			"black":step += max(black - other.black,0)
		pos += step
	return pos
func subtract(other: Mana) -> Mana:
	var result := Mana.new()
	for color in to_dict().keys():
		result.set(color, max(0, get(color) - other.get(color)))
	return result
func set_script_property(color, value):
	match color:
		"generic":generic = value
		"red":red = value
		"blue":blue = value
		"green":green = value
		"earth":earth = value
		"white":white = value
		"black":black = value
func set_color(color: String, value: int) -> void:
	if color in keys():
		self.set_script_property(color, value)
