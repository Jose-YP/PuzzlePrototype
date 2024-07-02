extends Control

@export var chainDisplayTiming: float = 1.0

signal breakGain(beads)
signal levelUp(level)
signal HighScore
signal maxedLevel

const chainDisplayScene = preload("res://Scenes/UI/chain_totals.tscn")

var chainTotalArray: Array[PanelContainer] = []
var level: int = 1
var regScore: int = 0
var HiScore: int = 0
var currentBeads: int = 0
var levelUpthreshold: int = 0
var just_reached: bool = false

#______________________________
#INITIALIZATION
#______________________________
func _ready() -> void:
	HiScore = Globals.get_extreme()[0]
	%HiScoreText.text = str("HISCORE: ", HiScore)
	levelUpthreshold = get_levelup_Threshold(level)

#______________________________
#SCORE MANIP
#______________________________
func update_score(score) -> void:
	regScore = score
	%ScoreText.text = str("SCORE: ",regScore)
	if regScore >= HiScore:
		update_HiScore(score)

func update_HiScore(score) -> void:
	#Notify the player when they reach the top spot
	if not just_reached:
		just_reached = true
		$Cheer.play()
		var cheerTween = create_tween().set_ease(Tween.EASE_OUT)
		cheerTween.tween_property($VBoxContainer/HiScoreContainer, "position", -5, .1)
		cheerTween.tween_property($VBoxContainer/HiScoreContainer, "position", 5, .1)
		cheerTween.tween_property($VBoxContainer/HiScoreContainer, "position", -5, .1)
		cheerTween.tween_property($VBoxContainer/HiScoreContainer, "position", 5, .1)
		cheerTween.tween_property($VBoxContainer/HiScoreContainer, "position", 0, .1)
	
	HiScore = score
	%HiScoreText.text = str("HISCORE: ", score)
	HighScore.emit()

#______________________________
#BEAD & LEVEL MANIP
#______________________________
func update_beads(beads) -> void:
	%BeadText.text = str("BEADS: ", beads)
	#Get how many were broken in a combo for breaker bead ruleset
	var breakNum = beads - currentBeads
	#New levelling system
	levelUpthreshold -= breakNum
	tween_levelUp(float(levelUpthreshold))
	if levelUpthreshold <= 0:
		print("level up!")
		update_level()
	
	if level == Globals.rules.max_levels:
		maxedLevel.emit()
	
	if Globals.rules.breakBead:
		breakGain.emit(breakNum)
		currentBeads = beads

func get_levelup_Threshold(lv) -> int:
	return roundi(Globals.rules.bead_levelUp + lv * Globals.rules.levelUp_rate)

func update_level() -> void:
	level = clamp(level + 1, 1, Globals.rules.max_levels)
	%LevelText.text = str("LEVEL: ", level)
	Globals.level = level
	levelUpthreshold = get_levelup_Threshold(level)
	levelUp.emit(level)
	tween_levelUp(float(get_levelup_Threshold(level)))

func tween_levelUp(currentValue: float):
	var currentThreshold = float(get_levelup_Threshold(level))
	var target = clamp((currentThreshold - currentValue) / currentThreshold, 0, 100) * 100
	var levelTween = self.create_tween().set_ease(Tween.EASE_IN)
	levelTween.tween_property(%LevelProgress,"value",target,.1)

#______________________________
#CHAIN DISPLAY MANIP
#______________________________
func show_display() -> PanelContainer:
	var chainDisplay = chainDisplayScene.instantiate()
	$VBoxContainer/DisplayContainer.add_child(chainDisplay)
	chainTotalArray.append(chainDisplay)
	chainDisplay.connect("remove",hide_display)
	
	var displayTween = self.create_tween()
	displayTween.tween_property(chainDisplay, "modulate", Color.WHITE, chainDisplayTiming)
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
		chainText = str(chainText, chains + 1, " Combo")
	else:
		chainText = str(chainText, chains, " Chain")
	
	display.text.append_text(str(beads," Beads\n", links," Links",chainText))
	display.displayTime.start()
	
	if Globals.NewgroundsToggle:
		if chains + 1 >= 3:
			%Sea.unlock()
		
		if links >= 15:
			%Earth.unlock()

func hide_display(chainDisplay):
	var displayTween = self.create_tween()
	displayTween.tween_property(chainDisplay, "modulate", Color.TRANSPARENT, chainDisplayTiming)
	await displayTween.finished
	#This should only be true when the hide tween finishes
	chainDisplay.finishedTween = true
	$Timer.start()

#Will be called upon chains ending
#Keep seperate so displays don't jump position
func remove_displays():
	for chainDisplay in chainTotalArray:
		if chainDisplay.finishedTween:
			chainTotalArray.erase(chainDisplay)
			chainDisplay.queue_free()
	
	if chainTotalArray.size() != 0:
		$Timer.start()

func _on_summn_pressed():
	var randBool = true
	if randi() % 2 == 0:
		randBool = false
	
	#update_beads(currentBeads + 5)
	update_display(randi_range(6,30), randi_range(2,12), randi_range(1,5), randBool)
