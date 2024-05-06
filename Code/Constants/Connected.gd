extends AnimatedSprite2D

const horiRot: int = 45

func set_color(chainColor):
	material.set_shader_parameter("otherColor",chainColor)
func set_color(connectColor):
	material.set_shader_parameter("otherColor",connectColor)

func fade_tweenout():
	var start: float = get_fade()
	var tween = get_tree().create_tween();
	tween.tween_method(set_fade, start, 1.0, .3)

func set_fade(value):
	material.set_shader_parameter("margin",value)

func get_fade():
	return material.get_shader_parameter("margin")
