extends CharacterBody3D

@export var mouse_sensitivity = 0.002
@export var SPEED = 90.0
@export var damage_base = 5

@onready var CameraFPS = $Camera3D
@onready var Armature = $Armature/Skeleton3D
@onready var animation = $AnimationPlayer
@onready var ray_cast_attack = $Camera3D/RayCast3D
@onready var areaparry = $Camera3D/AreaParry

###################TIMERS############################

@onready var timer_attack = $Timer_attack
@onready var timer_attack_impact = $Timer_attack_impact
@onready var timer_attack_charge = $Timer_attack_charge
@onready var timer_pull = $Timer_pull
@onready var timer_grab = $Timer_grab
@onready var timer_grab_punch = $Timer_grab_punch
@onready var timer_block = $Timer_block
@onready var timer_grab_connected = $Timer_grab_connected
@onready var timer_throw = $Timer_throw
@onready var timer_dash = $Timer_dash
###################TIMERS############################


##################STATES###########################

var attack_state = false
var block_state = false
var killing_blow = false
var grab_state = false
var pull_state = false
var clinch_state = false
var throw_state = false
var grab_punch_state = false
var grab_idle_transition_state = false
var dash_state = false
var power_attack_release_state = false
var attack_charge_state = false
var enemy_raycast_collided = null

##################STATES###########################
var nr

var right_left_hand = true
var last_action = "new"
var last_action_release = "new"
var enemy_body_ID
var attack_connection = false

var fr = ["attackL", "attackR", "PowerAttack", "throw", "grab", "grab_punch"]
var action_array = []
var variety = 1
var variety_for_text = 1
var damage = 1

var parry_ok = false
var successfull_parry = false

var y_rotation = 0.0
var x_rotation = 0.0

const JUMP_VELOCITY = 4.5


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	
func _physics_process(delta: float) -> void:

	move()
	move_and_slide()
	buffer() #it needs to be called before other actions
	#dash()
	#dash_vault_over()
	attack()
	#attack_release()
	block()
	#parryCondition()
	grab()
	grab_punch()
	#letGoOfTheDead()
	throw()
	#get_hurt()
	
	#Global_variables_functions.player_position = get_position()
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		y_rotation -= event.relative.x * mouse_sensitivity
		x_rotation -= event.relative.y * mouse_sensitivity
		
		x_rotation = clamp(x_rotation, deg_to_rad(-90), deg_to_rad(90))
		
		rotation.y = y_rotation
		CameraFPS.rotation.x = x_rotation
		CameraFPS.rotation.y = y_rotation
		Armature.rotation.x = -x_rotation
		Armature.rotation.y = y_rotation
	
	
func move():
	
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (CameraFPS.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	print(CameraFPS.global_rotation)
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)


func dash_seq():
	pass


func attack_seq():
	
	attack_state = true
	
	timer_attack.start(0.83)
	timer_attack_impact.start(0.5)
	
	if (right_left_hand == true):
		animation.play("Attack_R")
		right_left_hand = false
		
	else:
		animation.play("Attack_L")
		right_left_hand = true


func attack():

	if (Input.is_action_just_pressed("attack")) && (attack_state == false) && (block_state == false) && (grab_state == false) && (pull_state == false) && (clinch_state == false) && (throw_state == false) && (grab_idle_transition_state == false) && (dash_state == false) && (power_attack_release_state == false) && (attack_charge_state == false):
		attack_seq() 


func attack_buffer():
	
	if (block_state == false):
		attack_seq()


func attack_charge():
	
	if(Input.is_action_pressed("attack")) && (attack_charge_state == false):
		attack_charge_state = true
		timer_attack.stop()
		timer_attack_impact.stop()
		timer_attack_charge.start(1.4)
		if (right_left_hand == true):
			animation.play("Power_attack_charge_L")
			
		else:
			animation.play("Power_attack_charge_R")
			
		#print("Charge")


func block_seq():
	
	areaparry.monitoring = true
	block_state = true
	
	if (attack_state == true) || (grab_state == true) || (throw_state == true) || (grab_punch_state == true) || (attack_charge_state == true) || (power_attack_release_state == true):	
		last_action = "new"
		
	attack_state = false
	grab_state = false
	pull_state = false
	clinch_state = false
	throw_state = false
	killing_blow = false 
	grab_idle_transition_state = false
	grab_punch_state = false
	power_attack_release_state = false
	attack_charge_state = false
	enemy_raycast_collided = null
	timer_pull.stop()
	timer_attack.stop()
	timer_attack_impact.stop()
	timer_grab.stop()
	timer_grab_punch.stop()
	timer_attack_charge.stop()
	animation.stop()
	animation.play("Block")
	timer_block.start(0.41)


func block():
	
	if(Input.is_action_just_pressed("block")) && (block_state == false) && (dash_state == false):
		block_seq()


func block_buffer():
	
	block_seq()


func grab_seq():
	grab_state = true
	animation.play("Grab")
	timer_grab.start(0.5)
	timer_grab_connected.start(0.23)


func grab():
	if (Input.is_action_just_pressed("grab")) && (block_state == false) && (attack_state == false) && (grab_state == false) && (pull_state == false) && (clinch_state == false) && (throw_state == false) && (grab_idle_transition_state == false) && (dash_state == false) && (power_attack_release_state == false) && (attack_charge_state == false):
		grab_seq()


func grab_buffer():
	if (block_state == false)&& (attack_state == false) && (grab_state == false) && (pull_state == false) && (clinch_state == false) && (throw_state == false) && (power_attack_release_state == false):
		grab_seq()


func grab_punch_seq():
	
	grab_punch_state = true
	animation.stop()
	animation.play("Grab_punch")
	timer_grab_punch.start(0.5)


func grab_punch():
	
	if (Input.is_action_just_pressed("attack")) && (clinch_state == true) && (pull_state == false) && (grab_punch_state == false) && (grab_idle_transition_state == false):
		grab_punch_seq()
	
	if (Input.is_action_just_pressed("attack")) && (clinch_state == false) && (pull_state == true) && (grab_punch_state == false) && (grab_idle_transition_state == false):
		grab_punch_seq()
		timer_pull.stop()
		pull_state = false
		clinch_state = true


func grab_punch_buffer():
	
	grab_punch_state = false
	
	if (ray_cast_attack.is_colliding()):
		enemy_body_ID = ray_cast_attack.get_collider()
		attack_connection = true
		comboVariety("grab_punch")
		
	else:
		attack_connection = false

	choose_action_buffer()


func throw():
	
	if (Input.is_action_just_pressed("grab")) && ((pull_state == true) || (clinch_state == true)):
		throw_state = true
		pull_state = false
		clinch_state = false
		grab_punch_state = false
		grab_idle_transition_state = false
		comboVariety("throw")
		timer_pull.stop()
		timer_grab_punch.stop()
		animation.play("Throw")
		timer_throw.start(0.3)


func throw_buffer():
	if ((pull_state == true) || (clinch_state == true)):
		throw_state = true
		pull_state = false
		clinch_state = false
		killing_blow = false
		grab_punch_state = false
		grab_idle_transition_state = false
		timer_pull.stop()
		timer_grab_punch.stop()
		animation.play("Throw")
		timer_throw.start(0.3)


func grab_punch_idle_transition():
	grab_idle_transition_state = false


func buffer():
	
	if (timer_attack.is_stopped() == false) || (timer_block.is_stopped() == false) || (timer_grab.is_stopped() == false) || (timer_grab_punch.is_stopped() == false) || (timer_dash.is_stopped() == false) || (timer_attack_charge.is_stopped() == false) || (animation.current_animation == "Power_attack_release_L") || (animation.current_animation == "Power_attack_release_R"):
		
		if(Input.is_action_just_pressed("attack")):
			
			if (clinch_state == false):
				#print("ATTACK")
				last_action = "attack"
			else:
				#print("GRAB_PUNCH", nr)
				last_action = "grab_punch"
			
		if(Input.is_action_just_pressed("block")):
			#print("BLOCK")
			last_action = "block"
			
		if(Input.is_action_just_pressed("grab")):
			
			if (clinch_state == false) && (pull_state == false):
				#print("GRAB")
				last_action = "grab"
			else:
				#print("THROW")
				last_action = "throw"
		
		if(Input.is_action_just_pressed("dash")):
			last_action = "dash"



func choose_action_buffer():


	if (last_action == "attack"):
		attack_buffer()
		last_action_release = "attack"
	
	if (last_action == "block"):
		block_buffer()
	
	if (last_action == "grab"):
		grab_buffer()
	
	if (last_action == "grab_punch"):
		grab_punch_buffer()
	
	if (last_action == "throw"):
		throw_buffer()
	
	if (last_action == "dash"):
		dash_seq()
	
	
	last_action = "new"
	nr = 0


func comboVariety(action_name):
	
	action_array.push_back(action_name)
	
	##################################################
	
	for i in range(0, fr.size()):
		if(action_array.has(fr[i])):
			variety += 1

	if (parry_ok == true) && ((action_name == "attackR") || (action_name == "attackL") || (action_name == "grab_punch") || (action_name == "PowerAttack")):
		parry_ok = false
		
		if((action_name == "PowerAttack")):
			damage = damage_base * variety * 2 * 2
		else:
			damage = damage_base * variety * 2
		#print("PARRY_HIT")
	else:
		if((action_name == "PowerAttack")):
			damage = damage_base * variety * 2
		else:
			damage = damage_base * variety
	
	
	#print(action_array)
	print(damage)
	#print(action_array.size())
	variety_for_text = variety
	variety = 1
	
	
####################################\/TIMER_EFFECTS\/#####################################

func _on_timer_attack_timeout() -> void:
	attack_state = false
	
	choose_action_buffer()
	attack_charge()


func _on_timer_attack_impact_timeout() -> void:
	
	if (ray_cast_attack.is_colliding()):
		enemy_body_ID = ray_cast_attack.get_collider()
		attack_connection = true
		#print(enemy_body_ID)
		if (right_left_hand == true):
			comboVariety("attackL")
		else:
			comboVariety("attackR")
		#print(combo_metter)
	else:
		attack_connection = false


func _on_timer_attack_charge_timeout() -> void:
	pass # Replace with function body.


func _on_timer_grab_timeout() -> void:
	
	grab_state = false
	choose_action_buffer()


func _on_timer_pull_timeout() -> void:
	pull_state = false
	clinch_state = true
	animation.play("Clinch")


func _on_timer_grab_punch_timeout() -> void:
	
	grab_punch_state = false
	
	if (ray_cast_attack.is_colliding()):
		enemy_body_ID = ray_cast_attack.get_collider()
		attack_connection = true
		comboVariety("grab_punch")
		
	else:
		attack_connection = false

	choose_action_buffer()


func _on_timer_block_timeout() -> void:
	
	block_state = false
	successfull_parry = false
	
	choose_action_buffer()
	attack_charge()


func _on_timer_grab_connected_timeout() -> void:
	
	if (ray_cast_attack.is_colliding()):
		enemy_raycast_collided = ray_cast_attack.get_collider()
		grab_state = false
		pull_state = true
		comboVariety("grab")
		timer_grab.stop()
		animation.play("Pull")
		timer_pull.start(0.5)


func _on_timer_throw_timeout() -> void:
	
	throw_state = false
	enemy_raycast_collided = null


func _on_timer_dash_timeout() -> void:
	pass # Replace with function body.
