extends Control

@onready var nextBeads: Control = $VBoxContainer/NextBeads

signal levelUp(level)

var rules: Rules
var HiScore: int = 0
var level: int = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func update_next(beads):
	for i in range(3):
		nextBeads.update(i,beads[i])

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
	levelUp.emit(level)
