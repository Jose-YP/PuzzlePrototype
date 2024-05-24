extends Control

@export var chainDisplayTiming: float = 1.0

signal breakGain(beads)
signal levelUp(level)
signal HighScore
signal maxedLevel

const chainDisplayScene = preload("res://Scenes/UI/chain_totals.tscn")

var chainTotalArray: Array[PanelContainer] = []
var regScore: int = 0
var HiScore: int = 0
var currentBeads: int = 0
var level: int = 1

#______________________________
#INITIALIZATION
#______________________________
func _ready() -> void:
	HiScore = Globals.get_extreme()[0]
	%HiScoreText.text = str("HISCORE: ", HiScore)

#______________________________
#SCORE MANIP
#______________________________
func update_score(score) -> void:
	regScore = score
	%ScoreText.text = str("SCORE: ",regScore)
	if regScore >= HiScore:
		update_HiScore(score)

func update_HiScore(score) -> void:
	HiScore = score
	%HiScoreText.text = str("HISCORE: ", score)
	HighScore.emit()

#______________________________
#BEAD & LEVEL MANIP
#______________________________
func update_beads(beads) -> void:
	%BeadText.text = str("BEADS: ", beads)
	
	currentBeads = beads
	var levelThreshold: int = 1
	if level < Globals.rules.max_levels:
		levelThreshold = level_upThreshold(level)
	print("level: ", level," Threshold: ",levelThreshold)
	#Make code for beads being higher than rules.bead_levelUp * level
	%LevelProgress.value = clamp((beads - levelThreshold) / levelThreshold, 0, 100)
	if beads >= levelThreshold and level < Globals.rules.max_levels:
		print("level up!")
		update_level()
		%LevelProgress.value = 0
		#Check for even higher levels
		update_beads(beads)
	if level == Globals.rules.max_levels:
		maxedLevel.emit()
	

func level_upThreshold(lv) -> int:
	if lv <= 2:
		return roundi(Globals.rules.bead_levelUp + lv * Globals.rules.levelUp_rate)
	else:
		return roundi(Globals.rules.bead_levelUp + lv * Globals.rules.levelUp_rate) + level_upThreshold(lv - 1)

func update_level() -> void:
	level = clamp(level + 1, 1, Globals.rules.max_levels)
	%LevelText.text = str("LEVEL: ", level)
	Globals.level = level
	levelUp.emit(level)

#______________________________
#CHAIN DISPLAY MANIP
#______________________________
func show_display() -> PanelContainer:
	var chainDisplay = chainDisplayScene.instantiate()
	$VBoxContainer/DisplayContainer.add_child(chainDisplay)
	chainTotalArray.append(chainDisplay)
	chainDisplay.connect("remove",hide_display)
	
	var displayTween = self.create_tween()
	chainDisplay.midTween = true
	displayTween.tween_property(chainDisplay, "modulate", Color.WHITE, chainDisplayTiming)
	chainDisplay.midTween = false
	chainDisplay.text.clear()
	return chainDisplay

func update_display(beads, links, chains, breaker = false) -> void:
	#Get an avalible chainDisplay
	var display = show_display()
	
	display.text.clear()
	var chainText: String = "\n"
	if chains > 1 and not breaker:
		chainText = str(chainText, chains, " Chains")
	elif breaker:
		chainText = str(chainText, chains, " Combo")
	else:
		chainText = str(chainText, chains, " Chain")
	
	display.text.append_text(str(beads," Beads\n", links," Links",chainText))
	display.displayTime.start()

func hide_display(chainDisplay):
	var displayTween = self.create_tween()
	chainDisplay.midTween = true
	displayTween.tween_property(chainDisplay, "modulate", Color.TRANSPARENT, chainDisplayTiming)
	await displayTween.finished
	chainDisplay.midTween = false

#Will be called upon chains ending
#Keep seperate so displays don't jump position
func remove_displays():
	for chainDisplay in chainTotalArray:
		if not chainDisplay.midTween:
			chainTotalArray.erase(chainDisplay)
			chainDisplay.queue_free()
	
	if chainTotalArray.size() != 0:
		$Timer.start()

func _on_summn_pressed():
	var randBool = true
	if randi() % 2 == 0:
		randBool = false
	
	update_display(randi_range(6,30), randi_range(2,12), randi_range(1,5), randBool)
