extends Control

signal retry
signal main

var shown: bool = false

func start_focus():
	$VBoxContainer/HBoxContainer/Retry.grab_focus()
	shown = true

func _process(_delta):
	if shown:
		if Input.is_action_just_pressed("ui_accept"):
			get_viewport().gui_get_focus_owner().button_pressed = true

func _on_retry_pressed():
	retry.emit()

func _on_main_menu_pressed():
	main.emit()
