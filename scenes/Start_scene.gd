extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _on_btn_Credits_button_down():
	$bg_credit.visible = true


func _on_btn_Quit_button_down():
	get_tree().quit()


func _on_btn_Play_pressed():
	$bg_story.visible = true


func _on_btn_back_pressed():
	$bg_credit.visible = false


func _on_btn_Play_now_pressed():
	get_tree().change_scene("res://scenes/Terrain.tscn")
