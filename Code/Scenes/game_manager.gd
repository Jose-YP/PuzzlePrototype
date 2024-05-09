extends CanvasLayer

@onready var BoardSFX: Array[AudioStreamPlayer] = [%HoriMove, %Rotate, 
%HardDrop, %SoftDrop, %ETC]
@onready var MenuSFX: Array[AudioStreamPlayer] = [%MenuMove, %MenuConfirm,
 %MenuDeselect, %Pause]
@onready var music: AudioStreamPlayer = $Music/Music

func _ready():
	print("READY")

func _on_board_play_sfx(index):
	BoardSFX[index].play()
