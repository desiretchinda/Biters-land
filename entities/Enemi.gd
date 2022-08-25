extends KinematicBody

var MOVE_SPEED = 3
 
onready var raycast = $RayCast
onready var anim_player = $Zombie/AnimationPlayer

export(NodePath) var player_path

export(int) var health_full = 100

var current_health: int  

onready var health_bar = $HealthBar3d
 
var gr = -10   #GRAVITY
var player = null
var dead = false
var up = Vector3(0,1,0)

export(float) var delayResurrect = 10

var cmptDelayResurrect

var alreadyAttack: bool

var furry_mode:bool
var furry_delay = 10
var furry_chrono
var is_hill



 
func set_player():
	player = get_node(player_path)
   
func _ready():
	alreadyAttack = false
	furry_chrono = furry_delay
	is_hill = false
	
	anim_player.connect("animation_finished", self, "_animation_finish")
	anim_player.play("StanceBaked")
	set_player()
	add_to_group("enemies")
	cmptDelayResurrect = delayResurrect
	current_health = health_full
 
func _physics_process(delta):
	
	if is_hill:
		return
	
	if dead:
		cmptDelayResurrect -= delta
		
		if cmptDelayResurrect <= 0:
			cmptDelayResurrect = delayResurrect
			resurrect()
		return
		
	if player == null:
		return
		
	if player.gameManager.game_over or player.gameManager.goalAchieved:
		stop()
		return	

		
	if !is_on_floor():
		move_and_slide(Vector3(0,gr,0), Vector3(0,0,0))   #GRAVITY
		
	if furry_mode:
		MOVE_SPEED = 20
		furry_chrono -= delta
		if furry_chrono <= 0:
			furry_mode = false
			furry_chrono = furry_delay
	elif transform.origin.distance_squared_to(player.transform.origin) > 400:
		stop()
		return;

	
   
	#GETTING PLAYER VECTOR
	var vec_to_player = Vector3(player.get_transform().origin.x - self.get_transform().origin.x, 0, player.get_transform().origin.z - self.get_transform().origin.z)
	vec_to_player = vec_to_player.normalized()
   
   
	move_and_collide(vec_to_player * MOVE_SPEED * delta)     #MOVING TO PLAYER
   
   
	var lookPos = player.get_transform().origin         #ROTATION TO PLAYER
	look_at(lookPos,Vector3(0,1,0))
	set_rotation(Vector3(0, get_rotation().y, 0))         #LOCKING IN Y AXIS
#	$cam.look_at(lookPos,Vector3(0,1,0))
#
	if raycast.is_colliding():               
		var coll = raycast.get_collider()
		if coll != null and coll.name == "Player":
			self.attack()
			if ! alreadyAttack and anim_player.current_animation == "AttackBaked" and anim_player.current_animation_position >= 0.4:
				player.update_health()
				alreadyAttack = true
		else:
			self.notattack()
	else:
		self.notattack()
 
func attack():
	anim_player.play("AttackBaked")
	MOVE_SPEED = 0
	
	pass
	
func stop():
	anim_player.play("StanceBaked")
	MOVE_SPEED = 7
	pass

func resurrect():
	dead = false
	anim_player.play("StanceBaked")
	current_health = health_full
	MOVE_SPEED = 7
	$CollisionShape.disabled = false
	health_bar.update_bar(health_full,health_full)
	pass
 
func notattack():
	anim_player.play("RunBaked")
	
	if not furry_mode:
		MOVE_SPEED = 7
 
func kill():
	dead = true
	$CollisionShape.disabled = true
	gr = 0
	anim_player.play("DieBaked")
	
	if is_hill:
		player.gameManager.game_over = true
		player.gameManager.label_reason_go.get_parent().show()
		player.gameManager.label_reason_go.text = player.gameManager.game_over_reason[2]

func hill():
	is_hill = true
	$Zombie.visible = false
	$ZombieHill.visible = true
 
func _animation_finish(anim):
	if anim == "AttackBaked":
		alreadyAttack = false
