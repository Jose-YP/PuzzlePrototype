extends HBoxContainer

@onready var progressBar: ColorRect = $PanelContainer/BreakProgress
@onready var breakNotifier: PanelContainer = $PanelContainer2
@onready var breakText: Label = $PanelContainer/Label

func _ready():
	if Globals.rules.breakBead:
		$PanelContainer2/VBoxContainer/RichTextLabel.text = "TO SPAWN A BREAKER BEAD"
	
	Globals.show_controls($PanelContainer2/VBoxContainer/RichTextLabel2/TextureRect)

# Called when the node enters the scene tree for the first time.
func set_ripple_center() -> Vector2:
	var center: Vector2 = $Sprite2D.global_position / (get_window().size as Vector2)
	center = Vector2(center.x,center.y)
	return center
