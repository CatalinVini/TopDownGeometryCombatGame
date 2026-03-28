extends CharacterBody3D

@export var mouse_sensitivity = 0.002
@export var SPEED = 90.0
@export var damage_base = 5
@export var gravity := 9.8

@onready var CameraFPS = $Camera3D
@onready var Armature = $Armature/Skeleton3D
@onready var animation = $AnimationPlayer
@onready var ray_cast_attack = $Camera3D/RayCastAttack3D
@onready var areaparry = $Camera3D/AreaParry
@onready var dash_path_node = $DashPath
@onready var dash_path_to_fallow = $DashPath/DashPathFallow
@onready var grab_dash_enemy = $Camera3D/GrabDashOverEnemy
@onready var AKBS = $AreaKnockBackStaggered

###################TIMERS############################

@onready var timer_attack = $Timer_attack
@onready var timer_attack_impact = $Timer_attack_impact
@onready var timer_attack_charge = $Timer_attack_charge
@onready var timer_attack_release = $Timer_attack_release
@onready var timer_attack_release_impact = $Timer_attack_release_impact
@onready var timer_pull = $Timer_pull
@onready var timer_grab = $Timer_grab
@onready var timer_grab_punch = $Timer_grab_punch
@onready var timer_block = $Timer_block
@onready var timer_grab_connected = $Timer_grab_connected
@onready var timer_throw = $Timer_throw
@onready var timer_dash = $Timer_dash
@onready var timer_dash_recovery = $Timer_dash_reovery
@onready var timer_block_release = $Timer_block_release
@onready var timer_block_parry = $Timer_block_parry
@onready var timer_block_parriable = $Timer_block_parriable
@onready var timer_block_successfull = $Timer_block_successfull

###################TIMERS############################


##################STATES###########################

var attack_state = false
var block_state = false
var block_hold_state = false
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
var block_release_state = false
var block_parry_state = false
var block_parriable_state = false
var block_successfull_state = false

##################STATES###########################
var nr

var right_left_hand = true
var last_action = "new"
var last_action_release = "new"
var enemy_body_ID
var attack_connection = false
var power_attack_connection = false
var dash_nr = 2
var enemy_raycast_collided = null

var fr = ["attackL", "attackR", "PowerAttack", "throw", "grab", "grab_punch"]
var action_array = []
var variety = 1
var variety_for_text = 1
var damage = 1

var parry_ok = false
var successfull_parry = false

var y_rotation = 0.0
var x_rotation = 0.0

var enemy

const JUMP_VELOCITY = 4.5


func _ready():
	
	enemy = get_tree().get_first_node_in_group("Enemy_3D")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	grab_dash_enemy.add_exception($".")
	ray_cast_attack.add_exception($".")
	

func _physics_process(delta: float) -> void:

	if not is_on_floor():
		velocity.y -= gravity * delta
	
	move()
	move_and_slide()
	buffer() #it needs to be called before other actions
	dash()
	#dash_vault_over()
	attack()
	attack_release()
	block()
	block_release_from_hold()
	block_parry()
	block_parry_successfull()
	#parryCondition()
	grab()
	grab_punch()
	#letGoOfTheDead()
	throw()
	#get_hurt()
	
	Global_variables_functions.player_position_3D = get_position()


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
	#print(CameraFPS.global_rotation)
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x,0, SPEED)
		velocity.z = move_toward(velocity.z,0, SPEED)

	if (input_dir) && (attack_state == false) && (block_state == false) && (grab_state == false) && (pull_state == false) && (clinch_state == false) && (throw_state == false) && (grab_idle_transition_state == false) && (power_attack_release_state == false) && (attack_charge_state == false) && (block_hold_state == false) && (block_release_state == false) && (block_parry_state == false):
		animation.play("Move", 0.2)
	elif (input_dir == Vector2.ZERO) && (attack_state == false) && (block_state == false) && (grab_state == false) && (pull_state == false) && (clinch_state == false) && (throw_state == false) && (grab_idle_transition_state == false) && (power_attack_release_state == false) && (attack_charge_state == false) && (block_hold_state == false) && (block_release_state == false) && (block_parry_state == false):
		animation.play("Idle", 0.2)


func dash_seq():
	
	
	if (dash_nr > 0):
		if (Input.is_action_just_pressed("dash")) && ((grab_dash_enemy.get_collider() != enemy_raycast_collided) || (grab_dash_enemy.is_colliding() == false)) && (dash_state == false) && (block_state == false) && (block_hold_state == false) && (block_release_state == false):
			
			dash_state = true
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
			attack_charge_state = false
			power_attack_release_state = false
			enemy_raycast_collided = null
			timer_pull.stop()
			timer_attack.stop()
			timer_attack_impact.stop()
			timer_grab.stop()
			timer_grab_punch.stop()
			timer_attack_charge.stop()
			animation.stop()
			timer_dash.start(0.2)
			#print("DASH")
			
	if (dash_state == true):
		set_global_position(Vector3(dash_path_to_fallow.global_position.x, 0,dash_path_to_fallow.global_position.z))
		AKBS.monitorable = true
		
	if (Input.is_action_just_pressed("dash")) && (block_state == false) && (dash_nr > 0):
		dash_nr = dash_nr - 1
		timer_dash_recovery.start(1)


func dash():

	var input_dir = Input.get_vector("left", "right", "up", "down")
	#dash_path_node.rotation.x = CameraFPS.rotation.x
	dash_path_node.rotation.y = CameraFPS.rotation.y
	dash_path_node.rotation.z = CameraFPS.rotation.z
	dash_path_node.curve.set_point_position(0, (Vector3(0, -200, 0)).normalized())
	dash_path_node.curve.set_point_position(1, (Vector3(input_dir.x, 0, input_dir.y)).normalized() * 10 + Vector3(0, 0, 0))
	dash_seq()


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

	if (Input.is_action_just_pressed("attack")) && (attack_state == false) && (block_state == false) && (grab_state == false) && (pull_state == false) && (clinch_state == false) && (throw_state == false) && (grab_idle_transition_state == false) && (dash_state == false) && (power_attack_release_state == false) && (attack_charge_state == false) && (block_hold_state == false) && (block_release_state == false) && (block_parriable_state == false) && (block_parry_state == false):
		attack_seq() 


func attack_buffer():
	
	if (Input.is_action_pressed("attack") == false) && (block_state == false) && (block_parry_state == false):
		attack_seq()
	elif (Input.is_action_pressed("attack")) && (block_state == false):
		right_left_hand = !right_left_hand


func attack_charge():
	
	if (Input.is_action_pressed("attack")) && (!Input.is_action_pressed("block")) && (attack_charge_state == false):
		attack_charge_state = true
		timer_attack.stop()
		timer_attack_impact.stop()
		timer_attack_charge.start(1.4)
		if (right_left_hand == true):
			animation.play("Power_attack_charge_L", 0.2)
			
		else:
			animation.play("Power_attack_charge_R", 0.2)


func attack_release():
	
	if (Input.is_action_just_released("attack")) && (attack_charge_state == true):
		#print("Released")
		attack_charge_state = false
		animation.stop()
		
		if (timer_attack_charge.get_time_left() < 0.5):
			timer_attack_charge.stop()
			power_attack_release_state = true
			if (right_left_hand == true):
				animation.play("Power_attack_release_L")
			else:
				animation.play("Power_attack_release_R")
			timer_attack_release_impact.start(0.2)
			timer_attack_release.start(0.58)
			
		elif (timer_attack_charge.get_time_left() >= 0.5) && (timer_attack_charge.get_time_left() <= 1) && (last_action_release == "new"):
			
			timer_attack_charge.stop()
			attack_seq()
			
		elif (timer_attack_charge.get_time_left() >= 0.5) && (timer_attack_charge.get_time_left() <= 1) && (last_action_release == "attack"):
			timer_attack_charge.stop()
			attack_state = true
			timer_attack.start(0.83)
			timer_attack_impact.start(0.5)
			if (right_left_hand == true):
				animation.play("Attack_R")
			else:
				animation.play("Attack_L")
				
		elif (timer_attack_charge.get_time_left() > 1) && (timer_attack_charge.get_time_left() <= 1.4) && (last_action_release == "new"):
			
			timer_attack_charge.stop()
			attack_seq()
			
		elif (timer_attack_charge.get_time_left() > 1) && (timer_attack_charge.get_time_left() <= 1.4) && (last_action_release == "attack"):
			
			timer_attack_charge.stop()
			last_action_release = "new"
			attack_state = true
			timer_attack.start(0.83)
			timer_attack_impact.start(0.5)
			if (right_left_hand == true):
				animation.play("Attack_L")
			else:
				animation.play("Attack_R")


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
	animation.play("Block", 0.2, 1.3)
	timer_block.start(0.32)


func block():
	
	if (Input.is_action_just_pressed("block")) && (block_state == false) && (dash_state == false) && (block_release_state == false) && (block_hold_state == false) && (block_parry_state == false):
		block_seq()


func block_buffer():
	
	if (block_state == false) && (block_release_state == false) && (block_hold_state == false) && (block_parry_state == false):
		block_seq()


func block_hold():
	 
	if (Input.is_action_pressed("block")) && (block_parry_state == false) && (attack_state == false) && (grab_state == false) && (dash_state == false) && (block_state == false) && (block_hold_state == false) && (block_successfull_state == false) && (block_release_state == false):
		block_hold_state = true
		animation.play("Block_Hold")


func block_parry_seq():
	
	block_parry_state = true
	block_parriable_state = true
	if (attack_state == true) || (block_state == true) || (block_hold_state == true) || (grab_state == true) || (throw_state == true) || (grab_punch_state == true) || (attack_charge_state == true) || (power_attack_release_state == true):
		last_action = "new"
	
	successfull_parry = false
	block_state = false
	block_hold_state = false
	animation.play("Block_Parry", 0, 1.3)
	timer_block.stop()
	timer_block_parry.start(0.833/1.3)
	timer_block_parriable.start(0.3/1.3)


func block_parry():
	
	if(Input.is_action_pressed("block")) && (Input.is_action_just_pressed("attack")) && (block_parry_state == false) && (attack_state == false) && (grab_state == false) && (dash_state == false) && (block_release_state == false):
		block_parry_seq()


func block_parry_buffer():
	
	if (block_parry_state == false) && (attack_state == false) && (grab_state == false) && (dash_state == false) && (block_release_state == false):
		block_parry_seq()


func block_parry_successfull():
	
	if (block_parriable_state == true) && (enemy.attack_parry_connection == true) && (block_release_state == false):
		enemy.attack_parry_connection = false
		block_parry_state = false
		block_parriable_state = false
		block_state = false
		successfull_parry = false
		block_successfull_state = true
		timer_block_parry.stop()
		timer_block_parriable.stop()
		animation.play_section("Block_Parry", 0.3, 0.6, 1)
		timer_block_successfull.start(0.3)


func block_release_from_hold():
	
	if (Input.is_action_just_released("block")) && (block_hold_state == true) && (block_release_state == false) && (block_state == false) && (block_parry_state == false) && (block_parriable_state == false): 
		block_hold_state = false
		block_successfull_state = false
		block_release_state = true
		print("block_RELEASE_HOLD")
		animation.play("Block_Hold_Release", 0.2, 2)
		timer_block_release.start(0.58/2)


func block_release_seq():
	
	block_successfull_state = false
	block_release_state = true
	print("block_RELEASE")
	animation.play("Block_Hold_Release", 0.2, 2)
	timer_block_release.start(0.58/2)


func block_release():
	
	if (!Input.is_action_pressed("block")) && (block_release_state == false) && (block_parry_state == false) && (block_parriable_state == false):
		block_release_seq()


func grab_seq():
	
	grab_state = true
	animation.play("Grab")
	timer_grab.start(0.8)
	timer_grab_connected.start(0.5)


func grab():
	if (Input.is_action_just_pressed("grab")) && (block_state == false) && (attack_state == false) && (grab_state == false) && (pull_state == false) && (clinch_state == false) && (throw_state == false) && (grab_idle_transition_state == false) && (dash_state == false) && (power_attack_release_state == false) && (attack_charge_state == false) && (block_hold_state == false) && (block_release_state == false):
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
	
	if  (timer_attack.is_stopped() == false) || (timer_block_parry.is_stopped() == false) || (timer_block_successfull.is_stopped() == false) || (timer_block_release.is_stopped() == false) || (timer_grab.is_stopped() == false) || (timer_grab_punch.is_stopped() == false) || (timer_dash.is_stopped() == false) || (timer_attack_charge.is_stopped() == false):
		
		if(Input.is_action_just_pressed("attack")):
			
			if (clinch_state == false):
				#print("ATTACK")
				last_action = "attack"
			else:
				#print("GRAB_PUNCH", nr)
				last_action = "grab_punch"
			
		if (Input.is_action_just_pressed("block")):
			
			last_action = "block"	
			
			
		if (timer_block_release.is_stopped() == false) && (Input.is_action_just_pressed("block")):
			
			last_action = "block"
			print("LAST ACTION: ", last_action)
		
		elif (timer_block_release.is_stopped() == true) && (Input.is_action_just_released("block")):
			
			last_action = "block_released"
		
		
		if(Input.is_action_pressed("block") && (Input.is_action_just_pressed("attack"))):
			
			last_action = "block_parry"
			
			
		if(Input.is_action_just_pressed("grab")):
			
			if (clinch_state == false) && (pull_state == false):
				#print("GRAB")
				last_action = "grab"
			else:
				#print("THROW")
				last_action = "throw"
		
		if (Input.is_action_just_pressed("dash")):
			
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
	
	if (last_action == "block_parry"):
		block_parry_buffer()
	
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
	#print(damage)
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
		print(enemy_body_ID)
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
	
	block_hold()
	block_release()


func _on_timer_block_release_timeout() -> void: 
	
	block_release_state = false
	
	attack_charge()
	choose_action_buffer()


func _on_timer_block_parry_timeout() -> void:
	
	block_parry_state = false
	block_hold()
	choose_action_buffer()


func _on_timer_block_parriable_timeout() -> void:
	
	block_parriable_state = false


func _on_timer_block_successfull_timeout() -> void:
	
	block_successfull_state = false
	block_hold()


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


func _on_timer_attack_release_timeout() -> void:
	
	attack_state = false
	power_attack_release_state = false
	choose_action_buffer()
	attack_charge()


func _on_timer_attack_release_impact_timeout() -> void:
	
	if (ray_cast_attack.is_colliding()):
		enemy_body_ID = ray_cast_attack.get_collider()
		attack_connection = true
		power_attack_connection = true
		#print(enemy_body_ID)
		comboVariety("PowerAttack")
	else:
		attack_connection = false
		power_attack_connection = false 


func _on_timer_dash_timeout() -> void:
	
	dash_state = false
	AKBS.monitorable = false
	choose_action_buffer()


func _on_timer_dash_reovery_timeout() -> void:
	
	dash_nr += 1
	print("dash_nr + 1: ", dash_nr)
	
	if (dash_nr >= 2):
		print("dash recovered")
		timer_dash_recovery.stop()
	else:
		timer_dash_recovery.start(1)
