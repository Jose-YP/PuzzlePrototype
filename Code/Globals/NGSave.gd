extends Node

var save: Save
var userPrefs: UserPreferences

func _ready():
	add_to_group("CloudSave")

func _cloud_save():
	print(Globals.save, "||", Globals.userPrefs)
	return {
		"save" : Globals.save,
		"userPrefs" : Globals.userPrefs
	}
