extends Control

@export var chainDisplayTiming: float = 1.0

@onready var displayTime: Timer = $Timer

signal levelUp(level)
signal HighScore
signal maxedLevel

var rules: Rules
var regScore: int = 0
var HiScore: int = 0
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
	var levelThreshold: int = 1
	if level < rules.max_levels:
		levelThreshold = level_upThreshold(level)
	#Make code for beads being higher than rules.bead_levelUp * level
	%LevelProgress.value = clamp((beads - levelThreshold) / levelThreshold, 0, 100)
	if beads >= levelThreshold and level < rules.max_levels:
		update_level()
		%LevelProgress.value = 0
		#Check for even higher levels
		update_beads(beads)
	if level == rules.max_levels:
		maxedLevel.emit()
	

func level_upThreshold(lv) -> int:
	if lv <= 2:
		return roundi(rules.bead_levelUp + lv * rules.levelUp_rate)
	else:
		return roundi(rules.bead_levelUp + lv * rules.levelUp_rate) + level_upThreshold(lv - 1)

func update_level() -> void:
	level = clamp(level + 1, 1, rules.max_levels)
	%LevelText.text = str("LEVEL: ", level)
	Globals.level = level
	levelUp.emit(level)

#______________________________
#CHAIN DISPLAY MANIP
#______________________________
func show_display() -> void:
	var displayTween = self.create_tween()
	displayTween.tween_property($VBoxContainer/ChainTotals, "modulate", Color.WHITE, chainDisplayTiming)
	$VBoxContainer/ChainTotals/RichTextLabel.clear()

func update_display(beads, links, chains) -> void:
	$VBoxContainer/ChainTotals/RichTextLabel.clear()
	var chainText: String = "\n"
	if chains > 1:
		chainText = str(chainText, chains, " Chains")
	else:
		chainText = str(chainText, chains, " Chain")
	
	$VBoxContainer/ChainTotals/RichTextLabel.append_text(str(beads," Beads\n",
	links," Links\n",chains, " Chains"))
	displayTime.start()

func remove_display():
	var displayTween = self.create_tween()
	displayTween.tween_property($VBoxContainer/ChainTotals, "modulate", Color.TRANSPARENT, chainDisplayTiming)
	await displayTween.finished
	$VBoxContainer/ChainTotals/RichTextLabel.clear()
