extends PanelContainer

@onready var text: RichTextLabel = $RichTextLabel
@onready var timer: Timer = $Timer

signal remove

func _on_timer_timeout():
	remove.emit()
