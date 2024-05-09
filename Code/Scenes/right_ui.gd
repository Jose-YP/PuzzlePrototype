extends Control

signal levelUp(level)

var rules: Rules
var HiScore: int = 0
var level: int = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	update_HiScore(Globals.get_extreme()[0])

func update_score(score):
	%ScoreText.text = str("SCORE: ",score)
	if score >= HiScore:
		update_HiScore(score)

func update_HiScore(score):
	HiScore = score
	%HiScoreText.text = str("HISCORE: ", score)

func update_beads(beads):
	%BeadText.text = str("BEADS: ", beads)
	#Make code for beads being higher than rules.bead_levelUp * level
	%LevelProgress.value = beads % rules.bead_levelUp
	if %LevelProgress.value >= 100:
		update_level()
		%LevelProgress.value = 0

func update_level():
	level = clamp(level + 1, 1, rules.max_levels)
	%LevelText.text = str("LEVEL: ", level)
	Globals.level = level
	levelUp.emit(level)
