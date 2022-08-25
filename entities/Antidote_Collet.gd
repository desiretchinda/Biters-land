extends Area


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

enum TipeCollectable {Antidot = 1, GunBall = 2, Blaster = 3}

export(TipeCollectable) var tipeCollectable

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Antidote_body_entered(body):
		if body.name == "Player" and not body.gameManager.goalAchieved:
			if tipeCollectable == TipeCollectable.Antidot:
				body.gameManager.nbAntidotCollect += 1
				queue_free()
			elif tipeCollectable == TipeCollectable.GunBall:
				body.currentGunBall = body.gunBallTotal
				if body.currentAmor == 1:
					body.gameManager.label_amor.text = str(body.gunBallTotal)
			elif tipeCollectable == TipeCollectable.Blaster:
				body.gameManager.findBlaster = true
				body.nbAmor += 1
				queue_free()
		


func _on_Blaster_body_entered(body):
		if body.name == "Player" and not body.gameManager.goalAchieved:
			if tipeCollectable == TipeCollectable.Antidot:
				body.gameManager.nbAntidotCollect += 1
				queue_free()
			elif tipeCollectable == TipeCollectable.GunBall:
				body.currentGunBall = body.gunBallTotal
			elif tipeCollectable == TipeCollectable.Blaster:
				body.gameManager.findBlaster = true
				body.nbAmor += 1
				queue_free()

