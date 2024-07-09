extends PanelContainer

@onready var scoretext = $VBoxContainer/HBoxContainer/Scores.get_children()

signal refocus

# Called when the node enters the scene tree for the first time.
func _ready():
	refresh_scores()

func refresh_scores():
	var display = Globals.display
	var j = 0
	print(display)
	#i will increment by 1 and if messed with inside the loop
	#It'll revert to what it originally was before being messed with
	for i in range(0,scoretext.size(),2):
		#Two nodes will be edited in a loop
		scoretext[i].text = str(j+1,".\t", display[j][1])
		i += 1
		scoretext[i].text = str(display[j][0])
		j += 1

func _process(_delta):
	if visible:
		$VBoxContainer/Button.grab_focus()
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_cancel"):
			_on_button_pressed()

func _on_button_pressed():
	$".".hide()
	refocus.emit()
