extends VBoxContainer

@onready var progressBar: TextureProgressBar = $Progress/TextureProgressBar
@onready var breakNotifier: PanelContainer = $Info
@onready var breakNum: Label = $Progress/Label

func _ready():
	if Globals.rules.breakBead:
		$Info/VBoxContainer/RichTextLabel.text = "TO SPAWN A BREAKER BEAD"
	
	Globals.show_controls($Info/VBoxContainer/RichTextLabel2/TextureRect)

func set_breakNum(string):
	#If the break num is 0 hide it
	if string == "0":
		breakNotifier.hide()
	else:
		breakNotifier.show()
	
	breakNum.text = str(" ",string)

# Called when the node enters the scene tree for the first time.
func set_ripple_center() -> Vector2:
	var center: Vector2 = $Sprite2D.global_position / (get_window().size as Vector2)
	center = Vector2(center.x,center.y)
	return center
