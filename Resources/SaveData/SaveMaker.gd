extends Resource
class_name Save

@export var HiScores: Dictionary = {"999999":[1000,"YP!"],
"000000":[1200,"YP!"],
"111111":[999,"YP!"],
"222222":[3000,"YP!"],
"333333":[2000,"YP!"],
"444444":[1000,"YP!"]}

func save() -> void:
	ResourceSaver.save(self, "res://Resources/SaveData/SaveFile.tres")

static func load_or_create() -> Save:
	var res: Save = load("res://Resources/SaveData/SaveFile.tres") as Save
	if !res:
		res = Save.new()
	return res

func save_score(score,name):
	var id: String = ""
	for i in range(6):
		id = str(id,randi_range(0,9))
	HiScores[id] = [score,name]

func get_highScore():
	for score in HiScores:
		pass
	