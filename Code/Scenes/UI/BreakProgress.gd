extends HBoxContainer

@onready var progressBar: ColorRect = $PanelContainer/BreakProgress
@onready var breakNotifier: PanelContainer = $PanelContainer2
@onready var breakText: Label = $PanelContainer/Label

# Called when the node enters the scene tree for the first time.
func set_ripple_center() -> Vector2:
	var center: Vector2 = $Sprite2D.global_position / (get_window().size as Vector2)
	center = Vector2(center.x,center.y*2)
	return center
