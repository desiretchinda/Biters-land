extends KinematicBody

##################################################

var bar_green = preload("res://images/UI_HealthBar_Blue.png")
var bar_red = preload("res://images/UI_HealthBar_Red.png")
var bar_yellow = preload("res://images/UI_HealthBar_Yellow.png")

# Camera
export var mouse_sensitivity: float = 10.0
export var head_path: NodePath
onready var head: Spatial = get_node(head_path)
export var cam_path: NodePath
export var health_path: NodePath
onready var cam: Camera = get_node(cam_path)
onready var player_health_bar = get_node(health_path)
export var FOV: float = 80.0
var axis: Vector2 = Vector2()
# Move
var velocity: Vector3 = Vector3()
var direction: Vector3 = Vector3()
var mvarray: Array = [false, false, false, false] # FW, BW, L, R
var can_sprint: bool = true
var sprinting: bool = false
# Walk
export var gravity: float = 30.0
export var walk_speed: int = 10
export var sprint_speed: int = 16
export var acceleration: int = 8
export var deacceleration: int = 10
export var jump_height: int = 10
var grounded: bool
const FLOOR_NORMAL: Vector3 = Vector3(0, 1, 0)
# Fly
export var fly_speed: int = 10
export var fly_accel: int = 4
var flying: bool = false
# Slopes
export var floor_max_angle: float = 45
const VELOCITY_CLAMP: float = 0.25
export var ray_length = 400

onready var audioStream = $AudioStream;
onready var audioStream2 = $AudioStream2;

export(AudioStream) var gunWav;

export(AudioStream) var emptyGunWav;

export(int) var health = 100

export(NodePath) var gameManager_path
var gameManager
export(int) var gunBallTotal = 50

var nbAmor = 1

var currentAmor = 1

var currentGunBall
var dead

##################################################

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	gameManager = get_node(gameManager_path)
	cam.fov = FOV
	dead = false
	audioStream.stream = gunWav
	currentGunBall = gunBallTotal


func _physics_process(delta: float) -> void:	
	
	if gameManager.game_over or gameManager.goalAchieved:
		return
	
	camera_rotation(delta)
	
	if health <= 0:
		dead = true

	if flying:
		print_debug("Je vole");
		fly(delta)
	else:
		walk(delta)
		
		
func update_health():
	if health > 0:
		health -= int(rand_range(10, 20))
		update_bar(health, 100)

func _input(event: InputEvent) -> void:
	if gameManager.game_over or gameManager.goalAchieved:
		return
			
	# Change the amor here
	if event.is_action_pressed("change_amor"):
		if nbAmor >= 2:
			if currentAmor == 1:
				currentAmor = 2
				$Head/Camera/armor.hide()
				$Head/Camera/blaster.show()
				
				gameManager.ui_amor.hide()
				gameManager.ui_blaster.show()
				gameManager.label_amor.text = str(gameManager.blast_antidot_limit)
			else:
				currentAmor = 1
				$Head/Camera/armor.show()
				$Head/Camera/blaster.hide()
				
				gameManager.ui_amor.show()
				gameManager.ui_blaster.hide()
				gameManager.label_amor.text = str(currentGunBall)
		
	if event is InputEventMouseMotion:
		axis = event.relative
	
	if event.is_action_pressed("mouse_left"):	
		if currentAmor == 1:
			currentGunBall -= 1
			
			gameManager.label_amor.text = str(currentGunBall)
			
			if currentGunBall <= 0:
				gameManager.label_amor.text = str(0)
			
		if currentAmor == 2 and gameManager.objectifAchieved[0]:
			gameManager.blast_antidot_limit -= 1
			
			gameManager.label_amor.text = str(gameManager.blast_antidot_limit)
			
			if gameManager.blast_antidot_limit <= 0:
				gameManager.label_amor.text = str(0)
						
	
	# Herre to project the ray
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		
		#Play correct sound here
		if !audioStream.playing:
			if (currentAmor == 1 and currentGunBall < 0) or (currentAmor == 2 and (gameManager.blast_antidot_limit < 0 or !gameManager.objectifAchieved[0])) :
				currentGunBall = 0
				audioStream.stream = emptyGunWav
				audioStream.play();
			else:
				audioStream.stream = gunWav
				audioStream.play();
						
		var from = cam.project_ray_origin(event.position)
		var to = from + cam.project_ray_normal(event.position) * ray_length

		var result = get_world().direct_space_state.intersect_ray(cam.global_transform.origin, to, [self])

		# if we hit nothing - the flare is visible, so we show it
		if result.empty():
			pass
		else: # othwerwise we hide it
			if result.collider.is_in_group("enemies"):
				if currentAmor == 1: # Your amor to kill		
					if currentGunBall <= 0:
						return
					result.collider.current_health -= 10
					
					result.collider.health_bar.update_bar(result.collider.current_health, result.collider.health_full)
					if result.collider.anim_player.current_animation == "StanceBaked":
						result.collider.furry_mode = true
					if result.collider.current_health <= 0:
						result.collider.kill();
				elif currentAmor == 2 and gameManager.objectifAchieved[0]: # The antidote
					if gameManager.blast_antidot_limit <= 0:
						return
					
					result.collider.hill()
					gameManager.enemiesCures += 1
					

func walk(delta: float) -> void:
	# Input
	mvarray = [false, false, false, false]
	direction = Vector3()
	var aim: Basis = get_global_transform().basis
	if Input.is_action_pressed("move_forward"):
		direction -= aim.z
		mvarray[0] = true
	if Input.is_action_pressed("move_backward"):
		direction += aim.z
		mvarray[1] = true
	if Input.is_action_pressed("move_left"):
		direction -= aim.x
		mvarray[2] = true
	if Input.is_action_pressed("move_right"):
		direction += aim.x
		mvarray[3] = true
	direction.y = 0
	direction = direction.normalized()

	# Grounded or Not
	var snap: Vector3
	grounded = is_on_floor()

	# Jump
	if grounded:
		snap = Vector3(0, -1, 0)
		if Input.is_action_just_pressed("move_jump"):
			snap = Vector3(0, 0, 0)
			velocity.y = jump_height

	# Apply Gravity
	velocity.y += -gravity * delta

	# Sprint
	var speed: int
	if Input.is_action_pressed("move_sprint") && can_sprint && mvarray[0] == true && mvarray[1] != true:
		speed = sprint_speed
		cam.set_fov(lerp(cam.fov, FOV * 1.05, delta * 8))
		sprinting = true
	else:
		speed = walk_speed
		cam.set_fov(lerp(cam.fov, FOV, delta * 8))
		sprinting = false

	# Acceleration and Deacceleration
	# where would the player go
	var temp_vel: Vector3 = velocity
	temp_vel.y = 0
	var target: Vector3 = direction * speed
	var temp_accel: int
	if direction.dot(temp_vel) > 0:
		temp_accel = acceleration 
	else:
		temp_accel = deacceleration
	# interpolation
	temp_vel = temp_vel.linear_interpolate(target, temp_accel * delta)
	velocity.x = temp_vel.x
	velocity.z = temp_vel.z
	# clamping
	if direction.dot(velocity) == 0:
		if velocity.x < VELOCITY_CLAMP && velocity.x > -VELOCITY_CLAMP:
			velocity.x = 0
		if velocity.z < VELOCITY_CLAMP && velocity.z > -VELOCITY_CLAMP:
			velocity.z = 0

	# Move
#	if !audioStream2.playing and velocity.z != 0:
#		audioStream2.play()
		
	velocity.y = move_and_slide_with_snap(velocity, snap, FLOOR_NORMAL, true, 4, deg2rad(floor_max_angle)).y


func fly(delta: float) -> void:
	grounded = false

	# Input
	direction = Vector3()
	var aim = head.get_global_transform().basis
	if Input.is_action_pressed("move_forward"):
		direction -= aim.z
	if Input.is_action_pressed("move_backward"):
		direction += aim.z
	if Input.is_action_pressed("move_left"):
		direction -= aim.x
	if Input.is_action_pressed("move_right"):
		direction += aim.x
	direction = direction.normalized()

	# Acceleration and Deacceleration
	var target: Vector3 = direction * fly_speed
	velocity = velocity.linear_interpolate(target, fly_accel * delta)

	# Move
	velocity = move_and_slide(velocity)


func camera_rotation(delta: float) -> void:
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return
	if axis.length() > 0:
		var mouse_x: float = -axis.x * mouse_sensitivity * delta
		var mouse_y: float = -axis.y * mouse_sensitivity * delta

		axis = Vector2()

		rotate_y(deg2rad(mouse_x))

		head.rotate_x(deg2rad(mouse_y))

		var temp_rot: Vector3 = head.rotation_degrees
		temp_rot.x = clamp(temp_rot.x, -90, 90)
		head.rotation_degrees = temp_rot


func update_bar(amount, full):
	player_health_bar.texture_progress = bar_green
	
	if amount < 0.75 * full:
		player_health_bar.texture_progress = bar_yellow
	if amount < 0.45 * full:
		player_health_bar.texture_progress = bar_red
	
	player_health_bar.value = amount
