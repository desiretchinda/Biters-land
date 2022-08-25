extends TextureProgress


var bar_green = preload("res://images/greenHealthBar.png")
var bar_red = preload("res://images/redHealthBar.png")
var bar_yellow = preload("res://images/yellowHealthBar.png")

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func update_bar(amount, full):
	texture_progress = bar_green
	
	if amount < 0.75 * full:
		texture_progress = bar_yellow
	if amount < 0.45 * full:
		texture_progress = bar_red
	
	value = amount

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
