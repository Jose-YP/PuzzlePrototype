extends PanelContainer

@export var glowTab: int = 3

@onready var infoTabs: TabContainer = %InfoTabs
@onready var breakProgress: HBoxContainer = %BreakProgress
@onready var movementContainers: Array[Node] = %MovementContainer.get_children()
@onready var manipContainers: Array[Node] = %ManipContainer.get_children()
@onready var beadImgs: Array[TabContainer] = [%Earth, %Sea, %Air, %Light, %Dark]
@onready var glowImgs: Array[TabContainer] = [%NoGlow, %Glo, %Linked]
@onready var breakerImg: TabContainer = %Breaker

signal boardSFX(index)
signal makeSFX(index)
signal exit

var breakNum: int = 1

#______________________________
#INITIALIZATION
#______________________________
func _ready():
	for i in range(beadImgs.size()):
		beadImgs[i].current_tab = i
	for img in glowImgs:
		img.current_tab = glowTab
	breakerImg.current_tab = 6
	
	for i in range(movementContainers.size()):
		Globals.show_controls(movementContainers[i].get_child(0))
		Globals.show_controls(manipContainers[i].get_child(0))
	Globals.show_controls(%PauseTexture)
	
	%ScoringSystem2.clear()
	var use
	if Globals.rules.breakBead:
		use = str("FOR EVERY CONSECUTIVE BREAK YOU\'LL GAIN A ",Globals.rules.comboMultiplier * 100, "%")
	else:
		use = str("FOR EVERY CHAIN ON SCREEN YOU\'LL GAIN A X",Globals.rules.chainMultiplier)
	%ScoringSystem2.append_text(str("YOU\'LL ONLY SCORE ",Globals.rules.beadScore,
	" POINTS FOR EVERY BEAD BROKEN\n\nBUT FOR EVERY SET OF GLOWING BEADS IN A CHAIN ",
	"YOU\'LL ADD A ", Globals.rules.linkMultiplier * 100,"% MULTIPLIER FOR EVERY SET",
	" OF GLOWING BEADS\n\n", use ," MULTIPLIER FOR EVERY CHAIN ON SCREEN"))
	
	%LevellingSystem.clear()
	%LevellingSystem.append_text(str("AS BEADS GET BROKEN, YOU'LL LEVEL UP,",
	"WHICH WILL SPEED UP THE GAME AND TAKE YOU CLOSER TO THE END OF THE SESSION",
	"THERE ARE A MAX OF ", Globals.rules.max_levels, " LEVELS IN A SESSION"))
	
	%Glow.modulate = Globals.bead_colors[3]
	%Glow2.modulate = Globals.bead_colors[3]
	
	%DomainText.clear()
	%DomainText.append_text("[center]GLOWING ")
	%DomainText.push_color(Globals.bead_colors[0])
	%DomainText.append_text("EARTH ")
	%DomainText.pop()
	%DomainText.append_text("- ")
	%DomainText.push_color(Globals.bead_colors[1])
	%DomainText.append_text("SEA ")
	%DomainText.pop()
	%DomainText.append_text("- ")
	%DomainText.push_color(Globals.bead_colors[2])
	%DomainText.append_text("AIR")
	%DomainText.pop()
	%DomainText.append_text(" BEADS CONNECT TOGETHER")
	
	%EnergyText.clear()
	%EnergyText.append_text("[center]GLOWING ")
	%EnergyText.push_color(Globals.bead_colors[3])
	%EnergyText.append_text("LIGHT ")
	%EnergyText.pop()
	%EnergyText.append_text("- ")
	%EnergyText.push_color(Globals.bead_colors[4])
	%EnergyText.append_text("DARK")
	%EnergyText.pop()
	%EnergyText.append_text(" BEADS CONNECT TOGETHER")

#______________________________
#CONTROLS
#______________________________
func _on_exit_pressed():
	exit.emit()

func _on_next_pressed():
	if infoTabs.current_tab == 0:
		infoTabs.current_tab += 1
		%Next.text = str("Chains")
	else:
		infoTabs.current_tab -= 1
		%Next.text = str("Controls")
	makeSFX.emit(1)

func _on_main_menu_switch_tutorial():
	%Next.grab_focus()
