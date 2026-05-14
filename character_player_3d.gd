extends CharacterBody3D

@export var mouse_sensitivity = 0.002
@export var sensitivity = 2
@export var deadzone = 0.1
@export var SPEED = 90.0
@export var damage_base = 5
@export var gravity = 9.8
@export var HP = 100
@onready var HP_meter = $Camera3D/CanvasLayer/HealthBar
@export var DEF = 100

@onready var DEF_meter = $Camera3D/CanvasLayer/DefenseBar
@onready var CameraFPS = $Camera3D
@onready var Armature = $Armature/Skeleton3D
@onready var animation = $AnimationPlayer
@onready var ray_cast_attack = $Camera3D/RayCastAttack3D
@onready var areaparry = $Camera3D/AreaParry
@onready var AKBS = $AreaKnockBackStaggered
@onready var GrabMarker = $Marker3D

###################TIMERS############################

@onready var timer_general_states = $Timer_general_states
@onready var timer_perfect_block_window = $Timer_Perfect_Block_Window
@onready var timer_dash_recovery = $Timer_Dash_Recovery


var nr

var right_left_hand = true
var last_action = "new"
var last_action_release = "new"
var enemy_body_ID
var raycastcolis = false
var power_attack_connection = false
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

var input_vec = Input.get_vector("lookleft", "lookright", "lookup", "lookdown")
var vertical_look = 0.0
var current_look = Vector2.ZERO
var direction
const JUMP_VELOCITY = 4.5


enum State {
	IDLE,
	MOVE,
	DASH,
	ATTACK,
	ATTACK_CHARGE,
	ATTACK_RELEASE,
	BLOCK,
	BLOCK_HOLD,
	BLOCK_RELEASE,
	BLOCK_PARRY,
	BLOCK_PARRY_SUCCESS,
	GRAB,
	GRAB_CLINCH,
	GRAB_THROW,
	GRAB_PUNCH
}

var current_state: State = State.MOVE
var attack_damage_condition = false
var grab_punch_damage_condition = false
var attack_connection = false
var attack_one_hit = false
var grab_condition = false
var counter_ready = false
var B_simple_parried = false
var BPS = false
var dash_nr = 1


func _ready():
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	ray_cast_attack.add_exception($".")


func _physics_process(delta: float) -> void:

	if not is_on_floor():
		velocity.y -= gravity * delta
	
	function_call_NEW_way(delta)
	
	Global_3D.player_position_3D = get_position()


###############################################


func function_call_NEW_way(delta):
	
	move_seq()
	move_and_slide()
	aim(delta)
	handle_state(delta)
	get_hurt()
	buffer_states()


###############################################


func handle_state(delta):
	
	match current_state:
		State.IDLE:
			_idle_state()
		State.MOVE:
			_move_state()
		State.DASH:
			_dash_state()
		State.ATTACK:
			_attack_state()
		State.ATTACK_CHARGE:
			_attack_charge_state()
		State.ATTACK_RELEASE:
			_attack_release_state()
		State.BLOCK:
			_block_state()
		State.BLOCK_HOLD:
			_block_hold_state()
		State.BLOCK_RELEASE:
			_block_release_state()
		State.BLOCK_PARRY:
			_block_parry_state()
		State.BLOCK_PARRY_SUCCESS:
			_block_parry_success_state()
		State.GRAB:
			_grab_state()
		State.GRAB_CLINCH:
			_grab_clinch_state()
		State.GRAB_THROW:
			_grab_throw_state()
		State.GRAB_PUNCH:
			_grab_punch_state()


func change_state(new_state: State):
	
	if current_state == new_state:
		return
	
	exit_state(current_state)
	current_state = new_state
	enter_state(new_state)


func enter_state(state):
	
	match state:
		State.IDLE:
			print("PLAYER: Enter Idle")
		State.MOVE:
			print("PLAYER: Enter Move")
		State.DASH:
			print("PLAYER: Enter Dash")
		State.ATTACK:
			print("PLAYER: Enter Attack")
		State.ATTACK_CHARGE:
			print("PLAYER: Enter Attack Charge")
		State.BLOCK:
			print("PLAYER: Enter Block")
		State.BLOCK_HOLD:
			print("PLAYER: Enter Block_Hold")
		State.BLOCK_RELEASE:
			print("PLAYER: Enter Block_Release")
		State.BLOCK_PARRY:
			print("PLAYER: Enter Block_Parry")
		State.BLOCK_PARRY_SUCCESS:
			print("PLAYER: Enter Block_Parry_Success")
		State.GRAB:
			print("PLAYER: Enter Grab")
		State.GRAB_CLINCH:
			print("PLAYER: Enter Grab_Clinch")
		State.GRAB_THROW:
			grab_condition = false
			ray_cast_attack.enabled = true
			print("PLAYER: Enter Grab_Throw")
		State.GRAB_PUNCH:
			print("PLAYER: Enter Grab_Punch")


func exit_state(state):
	
	match state:
		State.IDLE:
			print("PLAYER: Exit Idle")
		State.MOVE:
			print("PLAYER: Exit Run")
		State.DASH:
			print("PLAYER: Exit Dash")
			SPEED = SPEED / 5 
		State.ATTACK:
			print("PLAYER: Exit Attack")
			for enemy in Global_3D.enemy_array:
				enemy.already_hit = false
		State.ATTACK_CHARGE:
			print("PLAYER: Exit Attack Charge")
		State.BLOCK:
			print("PLAYER: Exit Block")
		State.BLOCK_HOLD:
			print("PLAYER: Exit Block_Hold")
		State.BLOCK_RELEASE:
			print("PLAYER: Exit Block_Release")
		State.BLOCK_PARRY:
			print("PLAYER: Exit Block_Parry")
		State.BLOCK_PARRY_SUCCESS:
			print("PLAYER: Exit Block_Parry_Success")
		State.GRAB:
			print("PLAYER: Exit Grab")
		State.GRAB_CLINCH:
			print("PLAYER: Exit Grab_Clinch")
		State.GRAB_THROW:
			print("PLAYER: Exit Grab_Throw")
		State.GRAB_PUNCH:
			print("PLAYER: Exit Grab_Punch")


###############################


func _unhandled_input(event: InputEvent) -> void:
	
	if (event is InputEventMouseMotion):
		
		y_rotation -= event.relative.x * mouse_sensitivity
		x_rotation -= event.relative.y * mouse_sensitivity
		
		x_rotation = clamp(x_rotation, deg_to_rad(-80), deg_to_rad(80))
		
		rotation.y = y_rotation
		CameraFPS.rotation.x = x_rotation
		self.rotation.y = y_rotation
		
		if (current_state != State.GRAB_CLINCH) && (current_state != State.GRAB_PUNCH):
			Armature.rotation.x = -x_rotation
		else:
			Armature.rotation.x = 0


func aim(delta):
	
	if (Input.get_vector("lookleft","lookright","lookup","lookdown")):
		
		var x = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
		var y = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
		
		if abs(x) < deadzone:
			x = 0
		if abs(y) < deadzone:
			y = 0
		
		var look_input = Vector2(x, y)

		rotate_y(-look_input.x * sensitivity * delta)

		vertical_look -= look_input.y * sensitivity * delta
		vertical_look = clamp(vertical_look, deg_to_rad(-80), deg_to_rad(80))

		CameraFPS.rotation.x = vertical_look
		if (current_state != State.GRAB_CLINCH) && (current_state != State.GRAB_PUNCH):
			Armature.rotation.x = -vertical_look
		else:
			Armature.rotation.x = 0


func move_seq():
	
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var forward = CameraFPS.global_transform.basis.z
	var right = CameraFPS.global_transform.basis.x
	
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()
	
	
	
	if (current_state != State.DASH):
		
		direction = (right * input_dir.x + forward * input_dir.y).normalized()
		
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x,0, SPEED)
			velocity.z = move_toward(velocity.z,0, SPEED)


func TakeHPDamage(enemy):
	
	if (HP - enemy.damage > 0):
		HP = HP - enemy.damage
		HP_meter.value = HP
	elif (HP - enemy.damage <= 0):
		HP = 0
		HP_meter.value = HP


func TakeDEFDamage(enemy):
	
	if (DEF - enemy.damage > 0):
		DEF = DEF - enemy.damage
		DEF_meter.value = DEF
	elif (DEF - enemy.damage <= 0):
		DEF = 0
		DEF_meter.value = DEF


func get_hurt():
	
	for enemy in Global_3D.enemy_array:
		if (enemy.attack_hit_connection == true) && (enemy.hit_flag_on_player == false) && ((current_state != State.BLOCK) && (current_state != State.BLOCK_HOLD) && (current_state != State.BLOCK_PARRY)) && (BPS == false) && (B_simple_parried == false):
			enemy.attack_hit_connection = false
			enemy.hit_flag_on_player = true
			TakeHPDamage(enemy)
		
		if (enemy.attack_hit_connection == true) && (enemy.hit_flag_on_player == false) && ((current_state == State.BLOCK) || (current_state == State.BLOCK_HOLD) || (current_state == State.BLOCK_PARRY)) && (B_simple_parried == false) && (DEF > 0):
			enemy.attack_hit_connection = false
			enemy.hit_flag_on_player = true
			TakeDEFDamage(enemy)
			
		if (enemy.attack_hit_connection == true) && (enemy.hit_flag_on_player == false) && ((current_state == State.BLOCK) || (current_state == State.BLOCK_HOLD)) && (B_simple_parried == false) && (BPS == false) && (DEF == 0):
			enemy.attack_hit_connection = false
			enemy.hit_flag_on_player = true
			TakeHPDamage(enemy)
		
		if (enemy.attack_hit_connection == true) && (enemy.hit_flag_on_player == false) && (B_simple_parried == true):
			enemy.attack_hit_connection = false
			enemy.hit_flag_on_player = true
			GainDEF()


func GainDEF():
	
	if (DEF + 25 < 100):
		DEF = DEF + 25
		DEF_meter.value = DEF
	elif (DEF + 25 >= 100):
		DEF = 100
		DEF_meter.value = DEF


func buffer_states():

	if (timer_general_states.is_stopped() == false) && (timer_general_states.time_left < 0.3):
		
		if (current_state == State.ATTACK) || (current_state == State.ATTACK_RELEASE):
			
			if (Input.is_action_just_pressed("attack")):
				last_action = "attack"
			if (Input.is_action_just_pressed("grab")):
				last_action = "grab"
		
		if (current_state == State.BLOCK):
			
			if (Input.is_action_just_pressed("attack")):
				last_action = "attack"
			if (Input.is_action_just_pressed("grab")):
				last_action = "grab"
		
		if (current_state == State.GRAB):
			
			if (Input.is_action_just_pressed("grab")):
				last_action = "grab"
				
			if (Input.is_action_just_pressed("attack")):
				last_action = "attack"
		
		if (current_state == State.GRAB_PUNCH):
			
			if (Input.is_action_just_pressed("attack")):
				last_action = "grab_punch"
			
			if (Input.is_action_just_pressed("grab")):
				last_action = "throw"
				
		if (current_state == State.GRAB_THROW):
			
			if (Input.is_action_just_pressed("attack")):
				last_action = "attack"


func choose_action_buffer_states():

	if (last_action == "attack"):
		for enemy in Global_3D.enemy_array:
			enemy.already_hit = false
		change_state(State.ATTACK)
		last_action_release = "attack"
	
	if (last_action == "block"):
		change_state(State.BLOCK)
		
	if (last_action == "grab"):
		change_state(State.GRAB)
	
	if (last_action == "grab_punch"):
		change_state(State.GRAB_PUNCH)
	
	if (last_action == "throw"):
		change_state(State.GRAB_THROW)
	
	if (last_action == "dash"):
		change_state(State.DASH)
	
	if (last_action == "block_parry"):
		change_state(State.BLOCK_PARRY)
		
	last_action = "new"
	nr = 0


##################################


func _idle_state():
	
	var input_dir = Input.get_vector("left", "right", "up", "down")
	
	if (input_dir == Vector2.ZERO):
		animation.play("Idle", 0.2)
	
	if (input_dir):
		change_state(State.MOVE)
	
	if (Input.is_action_just_pressed("attack")):
		change_state(State.ATTACK)
	
	if (Input.is_action_just_pressed("block")):
		change_state(State.BLOCK)
	
	if (Input.is_action_just_pressed("grab")):
		change_state(State.GRAB)


func _move_state():
	
	var input_dir = Input.get_vector("left", "right", "up", "down")
	
	animation.play("Move", 0.2)
	
	if (Input.is_action_just_pressed("attack")):
		change_state(State.ATTACK)
	
	if (Input.is_action_just_pressed("block")):
		change_state(State.BLOCK)
		
	if (input_dir == Vector2.ZERO):
		change_state(State.IDLE)
		
	if (Input.is_action_just_pressed("dash")) && (dash_nr >= 1):
		change_state(State.DASH)
		
	if (Input.is_action_just_pressed("grab")):
		change_state(State.GRAB)


func _dash_state():
	
	if (timer_general_states.is_stopped()):
		animation.play("Move",0.2)
		timer_general_states.start(0.2)
		timer_dash_recovery.start(2)
		dash_nr -= 1
		SPEED = SPEED * 5
		
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x,0, SPEED)
			velocity.z = move_toward(velocity.z,0, SPEED)


func _attack_state():
	
	if (timer_general_states.is_stopped()):
		for enemy in Global_3D.enemy_array:
			enemy.already_hit = false
			
		if (right_left_hand == true):
			animation.play("Attack_R")
			timer_general_states.start(animation.get_current_animation_length())
			right_left_hand = false
		else:
			animation.play("Attack_L")
			timer_general_states.start(animation.get_current_animation_length())
			right_left_hand = true
		
	attack_impact()
		
	if (Input.is_action_just_pressed("block")):
		timer_general_states.stop()
		change_state(State.BLOCK)
	
	if (Input.is_action_just_pressed("dash")) && (dash_nr >= 1):
		timer_general_states.stop()
		change_state(State.DASH)


func _attack_charge_state():
	
	if (timer_general_states.is_stopped()):
		
		if (right_left_hand == true):
			animation.play("Power_attack_charge_R",0.2)
			timer_general_states.start(animation.get_current_animation_length())
		else:
			animation.play("Power_attack_charge_L",0.2)
			timer_general_states.start(animation.get_current_animation_length())
		
	if (Input.is_action_just_released("attack")) && (timer_general_states.time_left < 0.7):
		timer_general_states.stop()
		change_state(State.ATTACK_RELEASE)
	elif (Input.is_action_just_released("attack")) && (timer_general_states.time_left >= 0.7):
		timer_general_states.stop()
		change_state(State.ATTACK)


func _attack_release_state():
	
	if (timer_general_states.is_stopped()):
		for enemy in Global_3D.enemy_array:
			enemy.already_hit = false
			
		if (right_left_hand == true):
			animation.play("Power_attack_release_R")
			timer_general_states.start(animation.get_current_animation_length())
			right_left_hand = false
		else:
			animation.play("Power_attack_release_L")
			timer_general_states.start(animation.get_current_animation_length())
			right_left_hand = true

	attack_impact()

	if (Input.is_action_just_pressed("block")):
		timer_general_states.stop()
		change_state(State.BLOCK)
	
	if (Input.is_action_just_pressed("dash")) && (dash_nr >= 1):
		timer_general_states.stop()
		change_state(State.DASH)


func attack_impact():
	
	if (timer_general_states.get_time_left() < 0.5) && (timer_general_states.get_time_left() > 0.4) && ray_cast_attack.is_colliding(): 
		enemy_body_ID = ray_cast_attack.get_collider()
		attack_damage_condition = true
	else:
		attack_damage_condition = false


func _block_state():
	
	if (timer_general_states.is_stopped() == true):  
		animation.play("Block", 0.2, 1.5)
		timer_general_states.start(animation.current_animation_length / 1.5)
		if (DEF == 100):
			timer_perfect_block_window.start(0.3)
		
	if (Input.is_action_pressed("block") && Input.is_action_just_pressed("attack")):
		timer_general_states.stop()
		change_state(State.BLOCK_PARRY)
	
	if (Input.is_action_just_pressed("dash")) && (dash_nr >= 1):
		timer_general_states.stop()
		change_state(State.DASH)


func _block_hold_state():
	
	animation.play("Block_Hold", 0.2, 1)
	
	if (Input.is_action_just_released("block")):
		change_state(State.BLOCK_RELEASE)
	
	if (Input.is_action_pressed("block") && Input.is_action_just_pressed("attack")):
		change_state(State.BLOCK_PARRY)


func _block_parry_state():
	
	for enemy in Global_3D.enemy_array:
		
		if (timer_general_states.is_stopped() == true):
			animation.play("Block_Parry", 0.1, 1.5)
			timer_general_states.start(animation.current_animation_length / 1.5)
			
		if (enemy.attack_hit_connection == true) && (timer_perfect_block_window.is_stopped() == false) && (enemy.hit_flag_on_player == false) && (timer_general_states.time_left > 0.3 / 1.5): 
			BPS = true
			timer_general_states.stop()
			timer_perfect_block_window.start(0.3)
			change_state(State.BLOCK_PARRY_SUCCESS)
		elif (enemy.attack_hit_connection == true) && (timer_perfect_block_window.is_stopped() == true) && (enemy.hit_flag_on_player == false) && (timer_general_states.time_left > 0.5 / 1.5): 
			B_simple_parried = true
			timer_general_states.stop()
			timer_perfect_block_window.start(0.3)
			change_state(State.BLOCK_PARRY_SUCCESS)


func _block_parry_success_state():
	
	if (timer_general_states.is_stopped() == true):
		animation.play("Block_Parry_Successful", 0.1)
		timer_general_states.start((animation.current_animation_length))
		timer_perfect_block_window.start(0.9)
		
	if (Input.is_action_pressed("block") && (Input.is_action_just_pressed("attack"))):
		timer_general_states.stop()
		animation.stop(true)
		change_state(State.BLOCK_PARRY)
	
	if (!Input.is_action_pressed("block")) && (Input.is_action_just_pressed("attack")):
		timer_general_states.stop()
		timer_perfect_block_window.stop()
		change_state(State.ATTACK)
	
	if (Input.is_action_just_pressed("dash")) && (dash_nr >= 1):
		timer_general_states.stop()
		change_state(State.DASH)


func _block_release_state():
	
	if (timer_general_states.is_stopped() == true):
		animation.play("Block_Hold_Release", 0.2, 1.5)
		timer_general_states.start(animation.current_animation_length / 1.5)
		
	if (Input.is_action_just_pressed("attack")):
		timer_general_states.stop()
		change_state(State.ATTACK)
	
	if (Input.is_action_pressed("block")) && (Input.is_action_just_pressed("attack")):
		change_state(State.BLOCK_PARRY)
		if (DEF == 100):
			timer_perfect_block_window.start(0.3)
	
	if (Input.is_action_just_pressed("dash")) && (dash_nr >= 1):
		timer_general_states.stop()
		change_state(State.DASH)


func _grab_state():
	
	if (timer_general_states.is_stopped() == true):
		animation.play("Grab")
		timer_general_states.start(animation.current_animation_length)
	
	grab_impact()


func grab_impact():
	
	if (timer_general_states.time_left < 0.4) && (timer_general_states.time_left > 0.3) && ray_cast_attack.is_colliding():
		enemy_body_ID = ray_cast_attack.get_collider()
		grab_condition = true
		timer_general_states.stop()
		change_state(State.GRAB_CLINCH)
		ray_cast_attack.enabled = false
	else:
		grab_condition = false


func _grab_clinch_state():
	
	animation.play("Clinch", 0.2)
	GrabMarker.position = Vector3(0.0, 0.0, -15)
	
	if (Input.is_action_just_pressed("grab")):
		timer_general_states.stop()
		change_state(State.GRAB_THROW)
	
	if (Input.is_action_just_pressed("attack")):
		timer_general_states.stop()
		change_state(State.GRAB_PUNCH)


func _grab_throw_state():
	
	if (timer_general_states.is_stopped()):
		animation.play("Throw")
		timer_general_states.start(animation.current_animation_length)


func _grab_punch_state():
	
	if (timer_general_states.is_stopped()):
		enemy_body_ID.already_hit = false
		animation.stop(true)
		animation.play("Grab_punch")
		timer_general_states.start(animation.current_animation_length)
	
	grab_punch_impact()


func grab_punch_impact():
	
	if timer_general_states.time_left < 0.4 && timer_general_states.time_left > 0.2 && grab_punch_damage_condition == false && enemy_body_ID.already_hit == false:
		grab_punch_damage_condition = true


###################################


func _on_timer_general_states_timeout() -> void:
	
	attack_damage_condition = false
	if (!Input.is_action_pressed("attack")) && (current_state == State.ATTACK) && (last_action == "new"):
		change_state(State.IDLE)
		return
	elif (Input.is_action_pressed("attack")) && (current_state == State.ATTACK) && (last_action == "new"):
		change_state(State.ATTACK_CHARGE)
		return
	elif (!Input.is_action_pressed("attack")) && (current_state == State.ATTACK) && (last_action != "new"):
		choose_action_buffer_states()
		return
	
	if (current_state == State.ATTACK_CHARGE): 
		change_state(State.ATTACK_RELEASE)
		return
	
	if (current_state == State.ATTACK_RELEASE):
		change_state(State.IDLE)
		return
	
	if (current_state == State.BLOCK):
		if (Input.is_action_pressed("block")):
			change_state(State.BLOCK_HOLD)
			return
		else:
			if (last_action == "new") || (last_action == "block"):
				change_state(State.BLOCK_RELEASE)
				return
			elif (Input.is_action_pressed("attack")): 
				change_state(State.ATTACK_CHARGE)
				return
			else:
				choose_action_buffer_states()
				return
			
	if (current_state == State.BLOCK_RELEASE):
		change_state(State.IDLE)
		return
		
	if (current_state == State.DASH):
		change_state(State.IDLE)
		return
		
	if (current_state == State.BLOCK_PARRY):
		if (last_action == "new"):
			if (Input.is_action_pressed("block")):
				change_state(State.BLOCK_HOLD)
				return
			else:
				change_state(State.BLOCK_RELEASE)
				return
		else:
			animation.stop(true)
			choose_action_buffer_states()
			return
			
	if (current_state == State.BLOCK_PARRY_SUCCESS):
		animation.stop(true)
		
		if (last_action == "new"):
			if (Input.is_action_pressed("block")):
				change_state(State.BLOCK_HOLD)
				return
			else:
				change_state(State.BLOCK_RELEASE)
				return
		else:
			choose_action_buffer_states()
			return
	
	if (current_state == State.GRAB):
		
		if (last_action == "new"):
			change_state(State.IDLE)
			return
		else:
			choose_action_buffer_states()
			return 
			
	if (current_state == State.GRAB_THROW):
		
		if (last_action == "new"):
			change_state(State.IDLE)
			return
		else:
			choose_action_buffer_states()
			return
	
	if (current_state == State.GRAB_PUNCH):
		
		if (last_action == "new"):
			change_state(State.GRAB_CLINCH)
			return
		else:
			choose_action_buffer_states()
			return


func _on_timer_perfect_block_window_timeout() -> void:
	pass


func _on_timer_dash_recovery_timeout() -> void:
	
	if (dash_nr < 1):
		dash_nr += 1
