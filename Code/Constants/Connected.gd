extends AnimatedSprite2D

const horiRot: int = 45

func set_color(connectColor):
	material.set_shader_parameter("otherColor",connectColor)

func set_pos(place):
	#End points right or down when rotated
	#reverse pos to change direction
	match place:
		"Left":
			rotation_degrees = -horiRot
			translate(-$End.position)
		"Right":
			rotation_degrees = -horiRot
			translate($End.position)
		"Up":
			rotation_degrees = horiRot
			translate(-$End.position)
		"Down":
			rotation_degrees = horiRot
			translate($End.position)
