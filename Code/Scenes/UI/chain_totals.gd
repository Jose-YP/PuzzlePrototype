extends PanelContainer

@onready var text: RichTextLabel = $RichTextLabel
@onready var displayTime: Timer = $Timer

signal remove(who)

var midTween: bool = false

func _on_timer_timeout():
	remove.emit(self)
