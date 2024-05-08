extends Resource
class_name Save

@export var HiScores: Dictionary = {"999999":[1000,"YP!"],
"000000":[1000,"YP!"],
"111111":[1000,"YP!"],
"222222":[1000,"YP!"],
"333333":[1000,"YP!"],
"444444":[1000,"YP!"]}

func save_score(score,name):
	var id: String = ""
	for i in range(6):
		id = str(id,randi_range(0,9))
	HiScores[id] = [score,name]

func get_highScore():
	for score in HiScores:
		pass
	
