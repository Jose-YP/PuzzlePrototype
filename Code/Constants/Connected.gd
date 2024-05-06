extends AnimatedSprite2D

const horiRot: int = 45

func set_color(chainColor):
	material.set_shader_parameter("otherColor",chainColor)
