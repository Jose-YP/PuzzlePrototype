extends Node

func _ready():
	add_to_group("CloudSave")

func _cloud_save():
	print(Globals.save, Globals.userPrefs)
	return {
		"Save" : Globals.save,
		"UserPrefs" : Globals.userPrefs
	}
