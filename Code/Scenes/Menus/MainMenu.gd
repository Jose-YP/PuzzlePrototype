extends Control

@export var newH2pPosition: Vector2 = Vector2(-526,-330)
@export var orgH2pPosition: Vector2 = Vector2(-526,-1500)

@onready var buttons: Array[TextureButton] = [%PlayTex, %OptionsTex, %ScoresTex, %H2PTex]

signal switchPlay
signal switchOptions
signal switchTutorial
signal playSFX(index)
signal readied

var can: bool = false

#______________________________
#INITIALIZATION
#______________________________
func _ready() -> void:
	#This gives the computer some time to load in things
	var startTween = create_tween().set_trans(Tween.TRANS_QUAD)
	startTween.tween_property(self, "modulate", Color.WHITE, 1)
	await startTween.finished
	readied.emit()
	
	$"Score Display".refresh_scores()
	%PlayTex.grab_focus()
	can = true

func _process(_delta):
	if can and Input.is_action_just_pressed("ui_accept"):
		playSFX.emit(1)
		get_viewport().gui_get_focus_owner().button_pressed = true
	
	print(get_viewport().gui_get_focus_owner())

#______________________________
#BUTTON NAVIGATIONS
#______________________________
func _on_play_pressed() -> void:
	switchPlay.emit()

func _on_options_pressed() -> void:
	switchOptions.emit()

func _on_scores_pressed() -> void:
	$"Score Display".show()
	$"Score Display".pulled_down = true
	var scoreTween = self.create_tween()
	get_viewport().gui_get_focus_owner().release_focus()
	scoreTween.tween_property($"Score Display","position",Vector2(-114,-293),.05)
	await scoreTween.finished

func _on_how_2_play_pressed() -> void:
	$Light.unlock()
	$How2Play.self_modulate = Color.WHITE
	var h2pTween = self.create_tween()
	get_viewport().gui_get_focus_owner().release_focus()
	h2pTween.tween_property($How2Play,"position",newH2pPosition,.1)
	await h2pTween.finished
	switchTutorial.emit()

#______________________________
#SCORE AND BASIC CONTROLS
#______________________________
func _on_score_display_refocus() -> void:
	playSFX.emit(2)
	var scoreTween = self.create_tween()
	get_viewport().gui_get_focus_owner().release_focus()
	scoreTween.tween_property($"Score Display","position",Vector2(-114,-682), .05)
	await scoreTween.finished
	%ScoresTex.grab_focus()

func _on_focus_entered() -> void:
	if can:
		playSFX.emit(0)

#______________________________
#HOW TO PLAY SIGNALS
#______________________________
func _on_how_2_play_make_sfx(index):
	playSFX.emit(index)

func _on_how_2_play_exit():
	var h2pTween = self.create_tween()
	playSFX.emit(2)
	h2pTween.tween_property($How2Play,"position",orgH2pPosition,.1)
	await h2pTween.finished
	%H2PTex.grab_focus()

func _on_timer_timeout():
	$How2Play.position = orgH2pPosition
	$How2Play.modulate = Color.WHITE
