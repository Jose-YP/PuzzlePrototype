extends Node

func _ready():
	add_to_group("CloudSave")

func _cloud_save():
	print("AAAAAAAAA")
	return {
		"Save" : Globals.save,
		"UserPrefs" : Globals.userPrefs
	}
