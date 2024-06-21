extends HBoxContainer

@onready var progressBar: TextureProgressBar = $Progress/TextureProgressBar
@onready var rippleCenter: ColorRect = $Progress/BreakProgress
@onready var breakNotifier: PanelContainer = $Info
@onready var breakText: Label = $Info/Label

func _ready():
	if Globals.rules.breakBead:
		$Info/VBoxContainer/RichTextLabel.text = "TO SPAWN A BREAKER BEAD"
	
	Globals.show_controls($Info/VBoxContainer/RichTextLabel2/TextureRect)

# Called when the node enters the scene tree for the first time.
func set_ripple_center() -> Vector2:
	var center: Vector2 = $Sprite2D.global_position / (get_window().size as Vector2)
	center = Vector2(center.x,center.y)
	return center
