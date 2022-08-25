extends Sprite3D

onready var bar = $Viewport/healthBar2d

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	texture = $Viewport.get_texture()

func update_bar(amount, full):
	bar.update_bar(amount, full)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
