extends AnimatedSprite2D

const horiRot: int = 45

func set_color(connectColor):
	material.set_shader_parameter("otherColor",connectColor)
