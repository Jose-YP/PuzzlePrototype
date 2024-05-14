extends PanelContainer

@onready var scoreSystem: RichTextLabel = %ScoringSystem
@onready var levelSystem: RichTextLabel = %LevellingSystem
@onready var infoTabs: TabContainer = %InfoTabs
@onready var breakProgress = %BreakProgress
@onready var manipText: RichTextLabel = %FullBeadManip

signal boardSFX(index)
signal makeSFX(index)
signal exit

var breakNum: int = 1

func _ready():
	var upInput = OS.get_keycode_string(InputMap.action_get_events("ui_left")[0].keycode)
	var downInput = OS.get_keycode_string(InputMap.action_get_events("ui_right")[0].keycode)
	var leftInput = OS.get_keycode_string(InputMap.action_get_events("ui_up")[0].keycode)
	var rightInput = OS.get_keycode_string(InputMap.action_get_events("ui_down")[0].keycode)
	print(upInput,downInput,leftInput,rightInput)
	
	
	%Movement.clear()
	%Movement.append_text(str(leftInput,"/",rightInput," - MOVE LEFT AND RIGHT\n",upInput,
	" - HARD DROP [BEADS ARE THROWN TO THEIR LOWEST POSSIBLE POSITION]\n",downInput,
	" - SOFT DROP [BEADS MOVE DOWN ONE SPACE, WHEN PLACED THEY\'LL STICK TOGETHER]"))
	
	var CWWInput = OS.get_keycode_string(InputMap.action_get_events("ui_accept")[0].keycode)
	var ClockInput = OS.get_keycode_string(InputMap.action_get_events("ui_cancel")[0].keycode)
	var FlipInput = OS.get_keycode_string(InputMap.action_get_events("Flip")[0].keycode)
	var BreakInput = OS.get_keycode_string(InputMap.action_get_events("Break")[0].keycode)
	
	print(CWWInput,ClockInput,FlipInput,BreakInput)
	%FullBeadManip.clear()
	%FullBeadManip.append_text(str(CWWInput," - ROTATE COUNTER CLOCKWISE\n",
	ClockInput," - ROTATE CLOCKWISE\n",FlipInput
	," - FLIP BEADS NOT ON THE ANCHOR\n",BreakInput
	," - BREAK ALL CHAINS OF BEADS, [BREAK METER MUST BE FILLED]"))
	
	%ScoringSystem2.clear()
	%ScoringSystem2.append_text(str("YOU\'LL ONLY SCORE ",Globals.rules.beadScore,
	" POINTS FOR EVERY BEAD BROKEN\n\nBUT FOR EVERY SET OF GLOWING BEADS IN A CHAIN ",
	"YOU\'LL ADD A ", Globals.rules.linkMultiplier * 100,"% MULTIPLIER FOR EVERY SET",
	" OF GLOWING BEADS\n\nFOR EVERY CHAIN ON SCREEN YOU\'LL GAIN A X",
	Globals.rules.chainMultiplier," MULTIPLIER FOR EVERY CHAIN ON SCREEN"))
	
	%LevellingSystem.clear()
	%LevellingSystem.append_text(str("AS BEADS GET BROKEN, YOU'LL LEVEL UP,",
	"WHICH WILL SPEED UP THE GAME AND TAKE YOU CLOSER TO THE END OF THE SESSION",
	"THERE ARE A MAX OF ", Globals.rules.max_levels, " LEVELS IN A SESSION"))
	
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
	
