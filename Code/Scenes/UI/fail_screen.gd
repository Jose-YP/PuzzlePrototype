extends Control

signal retry
signal main

func _on_retry_pressed():
	retry.emit()

func _on_main_menu_pressed():
	main.emit()
