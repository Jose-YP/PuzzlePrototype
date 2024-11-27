extends Node2D

@export var Newgrounds: bool = true
@export var MusicOn: bool = true
@export var resetScores: bool = false
@export_range(0,.5,.01)  var pitchShift: float = .3

var saveRady = false
var readied = false
var transitioning = false
var gameManager = null

func _ready():
	first_ready()

func first_ready():
	await FinalGlobal.finalReady(Newgrounds)
	
	if resetScores:
		Globals.save.reset_scores() 
	
	if Globals.all_black():
		Globals.save.reset_colors()
		NGSaveSetup.sync_files()
	
	if Globals.save.background_id == 1:
		$ParallaxBackground.starting_change()
	
	await get_tree().create_timer(.25).timeout
	
	saveRady = true

func _process(_delta):
	if gameManager != null and saveRady and not readied:
		readied = true
		$ColorRect/RichTextLabel.clear()
		$ColorRect.connect("gui_input", start_for_real)
		$ColorRect/RichTextLabel.connect("gui_input", start_for_real)
		$ColorRect/RichTextLabel.append_text("[center]Click the screen to start")

func start_for_real(event):
	if not transitioning and readied and event is InputEventMouseButton:
		if event.get_button_index() == 1:
			transitioning = true
			
			var loaded = gameManager.instantiate()
			var loadedTween = get_tree().create_tween().set_ease(Tween.EASE_IN)
			get_tree().root.add_child(loaded)
			
			loadedTween.tween_property($ColorRect, "modulate", Color.TRANSPARENT, 1.0)
			await loadedTween.finished
			loaded.just_got_loaded()
			queue_free()

func _on_load_screen_finished(scene):
	var loadedTween = get_tree().create_tween().set_ease(Tween.EASE_IN) 
	gameManager = scene
	$LoadScreen.loadingText.clear()
	$LoadScreen.loadingText.append_text("[center]\n\nLoaded Main Game")
	loadedTween.tween_property($LoadScreen.loadingText, "modulate", Color.TRANSPARENT, 2.0)
	await loadedTween.finished
	$LoadScreen.queue_free()
