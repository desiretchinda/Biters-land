extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var hud_objectif = $Canvas/bgObjectif

onready var ui_amor = $Canvas/Hud_Stat/ui_amor

onready var ui_blaster = $Canvas/Hud_Stat/ui_blaster

onready var label_amor = $Canvas/Hud_Stat/LabelAmor

onready var label_reason_go = $Canvas/bg_reason/reason_game_over

onready var player = $Player

onready var bg_game_over = $Canvas/bgGO
onready var bg_game_pause = $Canvas/bgPause
onready var bg_game_victory = $Canvas/bg_victory

export(int) var nbAntidot = 4

export(int) var totalEnemies = 15

export(int) var blast_antidot_limit = 15

export var ui_capsules = []

var enemiesCures = 0

export var wpList = []

export var antidotList = []

var nbAntidotCollect

var findBlaster: bool

var goalAchieved:bool

var objectifAchieved = [false, false, false]

var objectifAchievedText = ["Recovers antidote capsules", "Find the blaster to inject the antidote", "Inject the antidote to the contaminated"]

var game_over_reason = ["You die", "Antidot insuffisant for all contaminated", "You kill and hill man"]

var game_over:bool = false

var go_delay = 5

var go_counter

# Called when the node enters the scene tree for the first time.
func _ready():
	$Blaster.get_node("CollisionShape").disabled = true
	nbAntidotCollect = 0
	go_counter = go_delay
	randomize()
	_spawn_antidot()
	pass # Replace with function body.


func _process(delta):
	

	
	if game_over and not bg_game_over.visible:
		go_counter -= delta
		
		if go_counter <= 0:
			bg_game_over.visible = true
			go_counter = go_delay
		return
	elif goalAchieved and not bg_game_victory.visible:
		go_counter -= delta
		
		if go_counter <= 0:
			bg_game_victory.visible = true
			go_counter = go_delay
		return

	if player.dead:
		game_over = true
		label_reason_go.get_parent().show()
		label_reason_go.text = game_over_reason[0]
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return
		
	if blast_antidot_limit <= (totalEnemies - enemiesCures) and enemiesCures < totalEnemies:
		game_over = true
		label_reason_go.get_parent().show()
		label_reason_go.text = game_over_reason[1]
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return

	_refresh_objectif()

	if goalAchieved:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event):
	if Input.is_key_pressed(KEY_ESCAPE) and not bg_game_pause.visible:
		#get_tree().quit()
		if !get_tree().paused:
			get_tree().paused = true
			bg_game_pause.visible = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _spawn_antidot():
	for antidot in antidotList:
		var pos = wpList[int(rand_range(0, wpList.size()))]
		get_node(antidot).visible = true
		get_node(antidot).translation = get_node(pos).translation
		wpList.erase(pos)

func _refresh_objectif():
	
	hud_objectif.get_node("obj1/textObj").text = str(nbAntidotCollect)+"/"+str(nbAntidot);
	hud_objectif.get_node("obj3/textObj").text = str(enemiesCures)+"/"+str(totalEnemies);
	
	if not objectifAchieved[0]:
		for i in range(nbAntidotCollect):
			get_node(ui_capsules[i]).show()
	
	if !objectifAchieved[0] and nbAntidotCollect >= nbAntidot:
		hud_objectif.get_node("obj1/tick").show();
		objectifAchieved[0] = true
		$Blaster.get_node("CollisionShape").disabled = false
		$Blaster.show()
			
	if !objectifAchieved[1] and findBlaster:
		objectifAchieved[1] = true
		hud_objectif.get_node("obj2/tick").show();
		
	if !objectifAchieved[2] and enemiesCures >= totalEnemies:
		objectifAchieved[2] = true
		hud_objectif.get_node("obj3/tick").show();
	
	if objectifAchieved[0] and objectifAchieved[1] and objectifAchieved[2]:
		goalAchieved = true


func _on_btn_play_pressed():
	get_tree().reload_current_scene()


func _on_btn_quit_pressed():
	get_tree().change_scene("res://scenes/Start_scene.tscn")


func _on_btn_continue_pressed():
	get_tree().change_scene("res://scenes/Start_scene.tscn")
