extends Node2D

@onready var ghostColor: Sprite2D = $Glow

func set_color(bead) -> void:
	if bead == null:
		ghostColor.self_modulate = Color.TRANSPARENT
		return
	
	match bead.typeID:
		5:
			ghostColor.self_modulate = Globals.breaker_color
		_:
			ghostColor.self_modulate = Globals.bead_colors[bead.typeID]
