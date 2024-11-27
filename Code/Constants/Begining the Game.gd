extends Node2D

@export var Newgrounds: bool = true
@export var MusicOn: bool = true
@export var resetScores: bool = false
@export_range(0,.5,.01)  var pitchShift: float = .3

var readied = false

func _ready():
	await FinalGlobal.finalReady(Newgrounds)
	
	if resetScores:
		Globals.save.reset_scores() 
	
	if Globals.all_black():
		Globals.save.reset_colors()
		NGSaveSetup.sync_files()
	
	if Globals.save.background_id == 1:
		$ParallaxBackground.starting_change()
	
	await get_tree().create_timer(.25).timeout
	
	$ColorRect/RichTextLabel.clear()
	$ColorRect.connect("gui_input", start_for_real)
	$ColorRect/RichTextLabel.connect("gui_input", start_for_real)
	$ColorRect/RichTextLabel.append_text("[center]Click the screen to start")

func start_for_real(event):
	if not readied and event is InputEventMouseButton:
		if event.get_button_index() == 1:
			#ready_playing(ETCMusic[0])
			var loadedTween = get_tree().create_tween()
			loadedTween.tween_property($ColorRect, "modulate", Color.TRANSPARENT, 1.0)
			$MainMenu.emit_signal("readied")
			readied = true
			await loadedTween.finished
			$ColorRect.hide()

func _on_load_screen_finished(scene):
	pass # Replace with function body.
