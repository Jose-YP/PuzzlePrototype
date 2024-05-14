extends PanelContainer

@onready var scoreSystem: RichTextLabel = %ScoringSystem
@onready var levelSystem: RichTextLabel = %LevellingSystem
@onready var infoTabs: TabContainer = %InfoTabs
@onready var breakProgress = %BreakProgress
@onready var moveText: RichTextLabel = %Movement
@onready var manipText: RichTextLabel = %FullBeadManip

signal boardSFX(index)
signal makeSFX(index)
signal exit

var breakNum: int = 1

func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("Break") and breakNum > 0:
		pass
	if Input.is_action_just_pressed("ui_accept"):
		%Next.press()
	if Input.is_action_just_pressed("ui_cancel"):
		%Exit.press()

func _on_exit_pressed():
	makeSFX.emit(2)
	exit.emit()

func _on_next_pressed():
	if infoTabs.current_tab == 0:
		infoTabs.current_tab += 1
		%Next.text = str("Chains")
	else:
		infoTabs.current_tab -= 1
		%Next.text = str("Controls")
	makeSFX.emit(1)
	
