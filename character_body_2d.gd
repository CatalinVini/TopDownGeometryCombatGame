extends CharacterBody2D

@export var speed = 400
@export var combo_metter = 1.0
@export var combo_multiplier = 1
@export var damage_base = 5
@export var parry_hit_damage = 50

var damage = 5

var some_zero: Vector2
var controllerAngle = Vector2.ZERO

@onready var hand_left = $"Hand L/AreaHandL2D"
@onready var hand_right = $"Hand R/AreaHandR2D"
@onready var animation = $"../AnimationPlayer"
@onready var timer_attack = $"../Timer_attack"
@onready var timer_attack_connected = $"../Timer_attack_hit"
@onready var timer_block = $"../Timer_block"
@onready var timer_grab = $"../Timer_grab"
@onready var timer_grab_connected = $"../Timer_grab_connected"
@onready var timer_pull = $"../Timer_pull"
@onready var timer_throw = $"../Timer_throw"
@onready var timer_grab_punch = $"../Timer_grab_punch"
@onready var timer_dash = $"../Timer_dash"
@onready var marker_hand = $"Hand L/Marker2D"
@onready var areaparry = $AreaParry2D
@onready var raycast = $RayCast2D
@onready var ALOCT = $AutoLockOnClosestTarget
@onready var path_node = $"../PathNode"
@onready var dodge_path = $"../PathNode/DodgePath"
@onready var dodge_path_to_fallow = $"../PathNode/DodgePath/PathFollow2D"
@onready var AKBS = $AreaKnockBackStaggered
@onready var timer_dash_recovery = $"../Timer_dash_recovery"
@onready var grab_dash_enemy = $"../PathNode/GrabDashOverEnemy"
@onready var timer_IFRAMES = $"../Timer_iframes"
@onready var timer_attack_charge = $"../Timer_attack_charge"


var fr = ["attackL", "attackR", "throw", "grab", "grab_punch"]
var action_array = ["attackL", "attackR", "throw", "grab", "grab_punch"]
var act_arr_length = action_array.size()
var nr = 0
var index_ac_arr = 0
var nr_fr = 0
var variety = 5
var variety_for_text = 5
var parry_ok = false
var dash_nr = 2

var attack_state = false
var block_state = false
var grab_state = false
var pull_state = false
var clinch_state = false
var grab_punch_state = false
var throw_state = false
var dash_state = false
var attack_charge_state = false
var power_attack_release_state = false
var in_buffer = false
var action_to_block_transition = false
var present_action = "new"
var last_action = "new"
var last_action_release = "new"
var second_last_action = "new"
var right_left_hand = false
var block_detection = false
var successful_parry = false
var attack_connection = false
var left_click_number = 0
var right_click_number = 0
var grab_button_pressed_number = 0
var successfull_parry = false
var killing_blow = false
var grab_idle_transition_state = false
var HitPoints = 100
var damage_per_hit = 20
var ALOCT_mode_switch = false
var dash_over_stun = false
var EnemySquare
var EnemyArray
var enemy_body_ID
var enemy_area_ID
var enemy_raycast_collided
var aux_enemy_raycast_collided


func _ready() -> void:
	EnemySquare = get_tree().get_first_node_in_group("Enemy")
	EnemyArray = get_tree().get_nodes_in_group("Enemy")
	grab_dash_enemy.add_exception(self)


func _physics_process(delta: float) -> void:
	
	lockOnTargetClosest()
	aiming()
	move()
	move_and_slide()
	buffer() #it needs to be called before other actions
	dash()
	dash_vault_over()
	attack()
	attack_release()
	block()
	parryCondition()
	grab()
	grab_punch()
	letGoOfTheDead()
	throw()
	get_hurt()
	
	Global_variables_functions.player_position = get_position()


func dash_seq():
	
	if (dash_nr > 0):
		if (Input.is_action_just_pressed("dash")) && ((grab_dash_enemy.get_collider() != enemy_raycast_collided)||(grab_dash_enemy.is_colliding() == false)) && (dash_state == false) && (block_state == false):
			
			dash_state = true
			if (attack_state == true) || (grab_state == true) || (throw_state == true) || (grab_punch_state == true):
				last_action = "new"
				
			attack_state = false
			grab_state = false
			pull_state = false
			clinch_state = false
			throw_state = false
			killing_blow = false 
			grab_idle_transition_state = false
			grab_punch_state = false
			enemy_raycast_collided = null
			timer_pull.stop()
			timer_attack.stop()
			timer_attack_connected.stop()
			timer_grab.stop()
			timer_grab_punch.stop()
			animation.stop()
			timer_dash.start(0.2)
	
	if (dash_state == true):
		set_global_position(dodge_path_to_fallow.global_position)
		AKBS.monitorable = true
		
	if (Input.is_action_just_pressed("dash")) && (block_state == false) && (dash_nr > 0):
		dash_nr = dash_nr - 1
		timer_dash_recovery.start(1)


func dash():
	
	path_node.global_position = self.global_position
	dodge_path.curve.set_point_position(1, Input.get_vector("left", "right", "up", "down") * 320)
	grab_dash_enemy.target_position = Input.get_vector("left", "right", "up", "down") * 320
	
	dash_seq()


func dash_vault_over():
	
	if (Input.is_action_just_pressed("dash")) && (grab_dash_enemy.get_collider() == enemy_raycast_collided) && ((clinch_state == true) || (pull_state == true)) && (dash_state == false): 
		
		self.set_collision_layer_value(1, false)
		self.set_collision_mask_value(1, false)
		self.set_collision_layer_value(8, true)
		self.set_collision_mask_value(8, true)
		timer_IFRAMES.start(0.2)
		dash_over_stun = true
		
		#print("DASH OVER")
		dash_state = true
		if (attack_state == true) || (grab_state == true) || (throw_state == true) || (grab_punch_state == true):
			last_action = "new"
			
		attack_state = false
		grab_state = false
		pull_state = false
		clinch_state = false
		throw_state = false
		killing_blow = false 
		grab_idle_transition_state = false
		grab_punch_state = false
		aux_enemy_raycast_collided = enemy_raycast_collided
		enemy_raycast_collided = null
		timer_pull.stop()
		timer_attack.stop()
		timer_attack_connected.stop()
		timer_grab.stop()
		timer_grab_punch.stop()
		animation.stop()
		timer_dash.start(0.2)


func aiming():

	if (ALOCT_mode_switch == false):
		if (Input.get_last_mouse_velocity()):
			look_at(get_global_mouse_position())
			#print("mouse control")
		elif(Input.get_vector("lookleft","lookright","lookup","lookdown")):
			controllerAngle=(Vector2(self.global_position.x + Input.get_joy_axis(0,JOY_AXIS_RIGHT_X), self.global_position.y + Input.get_joy_axis(0,JOY_AXIS_RIGHT_Y)))
			#print("X: ",Input.get_joy_axis(0,JOY_AXIS_RIGHT_X)," Y: ", Input.get_joy_axis(0,JOY_AXIS_RIGHT_Y))
			look_at(controllerAngle)


func lockOnTargetClosest():
	
	if (Input.is_action_just_pressed("AutoLockOnMode")):
		ALOCT_mode_switch = !ALOCT_mode_switch
	
	if (ALOCT_mode_switch == true) && (ALOCT.get_collider(0)):
		#print(ALOCT.get_collision_point(0))
		look_at(ALOCT.get_collision_point(0))


func move():
	
	var input_direction = Input.get_vector("left", "right", "up", "down")
	some_zero.x = 0
	some_zero.y = 0
	
	velocity = input_direction * speed
	#print(Input.get_vector("left", "right", "up", "down"))
	
	if (input_direction) && (attack_state == false) && (block_state == false) && (grab_state == false) && (pull_state == false) && (clinch_state == false) && (throw_state == false) && (grab_idle_transition_state == false) && (power_attack_release_state == false) && (attack_charge_state == false):
		animation.play("Move")
	elif (input_direction == some_zero) && (attack_state == false) && (block_state == false) && (grab_state == false) && (pull_state == false) && (clinch_state == false) && (throw_state == false) && (grab_idle_transition_state == false) && (power_attack_release_state == false) && (attack_charge_state == false):
		animation.play("Idle")


func attack_seq():
	
	attack_state = true
	timer_attack.start(0.5)
	timer_attack_connected.start(0.23)
	
	if (right_left_hand == true):
		animation.play("Attack_R")
		right_left_hand = false
		hand_right.monitoring = true
		
	else:
		animation.play("Attack_L")
		right_left_hand = true
		hand_left.monitoring = true


func attack_charge():
	
	if(Input.is_action_pressed("attack")) && (attack_charge_state == false):
		attack_charge_state = true
		timer_attack_charge.start(0.8)
		if (right_left_hand == true):
			animation.play("Power_attack_charge_L")
			
		else:
			animation.play("Power_attack_charge_R")
			
		print("Charge")


func attack_release():
	
	if (Input.is_action_just_released("attack")) && (attack_charge_state == true):
		print("Released")
		attack_charge_state = false
		
		if (timer_attack_charge.get_time_left() < 0.3):
			power_attack_release_state = true
			timer_attack_charge.stop()
			animation.stop()
			if (right_left_hand == true):
				animation.play("Power_attack_release_L")
			else:
				animation.play("Power_attack_release_R")
		elif (timer_attack_charge.get_time_left() >= 0.3) && (timer_attack_charge.get_time_left() <= 0.5):
			attack_state = true
			timer_attack.start(0.5)
			timer_attack_connected.start(0.23)
			if (right_left_hand == true):
				animation.play("Attack_R")
			else:
				animation.play("Attack_L")
		elif (timer_attack_charge.get_time_left() > 0.5) && (timer_attack_charge.get_time_left() <= 0.9) && (last_action_release == "new"):
			attack_seq()
			print("LAR: ", last_action_release)
		elif (timer_attack_charge.get_time_left() > 0.5) && (timer_attack_charge.get_time_left() <= 0.9) && (last_action_release == "attack"):
			print("LAR BUFF: ", last_action_release)
			last_action_release = "new"
			attack_state = true
			timer_attack.start(0.5)
			timer_attack_connected.start(0.23)
			if (right_left_hand == true):
				animation.play("Attack_L")
			else:
				animation.play("Attack_R")
				
func attack_release_impact():
	
	power_attack_release_state = false
	print(animation.current_animation)
	choose_action_buffer()
	attack_charge()


func attack():
	
	if (Input.is_action_just_pressed("attack")) && (attack_state == false) && (block_state == false) && (grab_state == false) && (pull_state == false) && (clinch_state == false) && (throw_state == false) && (grab_idle_transition_state == false) && (dash_state == false) && (power_attack_release_state == false) && (attack_charge_state == false):
		attack_seq() 
		
	if (Input.is_action_just_pressed("attack")):
		left_click_number = left_click_number + 1
		right_click_number = 0
		grab_button_pressed_number = 0


func attack_buffer():
	
	if (block_state == false):
		attack_seq()


func block_seq():
	
	areaparry.monitoring = true
	block_state = true
	
	if (attack_state == true) || (grab_state == true) || (throw_state == true) || (grab_punch_state == true):
		last_action = "new"
		
	attack_state = false
	grab_state = false
	pull_state = false
	clinch_state = false
	throw_state = false
	killing_blow = false 
	grab_idle_transition_state = false
	grab_punch_state = false
	enemy_raycast_collided = null
	timer_pull.stop()
	timer_attack.stop()
	timer_attack_connected.stop()
	timer_grab.stop()
	timer_grab_punch.stop()
	animation.stop()
	animation.play("Block")
	timer_block.start(0.5)


func block():
	
	if(Input.is_action_just_pressed("block")) && (block_state == false) && (dash_state == false):
		hand_right.monitoring = false
		hand_left.monitoring = false
		block_seq()

	if (Input.is_action_just_pressed("block")):
		right_click_number = right_click_number + 1
		left_click_number = 0
		grab_button_pressed_number = 0


func parryCondition():
	
	var EnemyArray = get_tree().get_nodes_in_group("Enemy")
	
	if (block_state == true):
		for enemy_paried in EnemyArray:
			if (enemy_paried.parried_state == true):
				parry_ok = true
				#print("POK")
				break
	

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
		
	if (Input.is_action_just_pressed("grab")):
		grab_button_pressed_number += 1
		left_click_number = 0
		right_click_number = 0


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
	
	if (clinch_state == true) && (pull_state == false) && (grab_punch_state == false):
		grab_punch_seq()


func letGoOfTheDead():
	
	if ((clinch_state == true) || (pull_state == true)):
		var EnemyArrayLocal = get_tree().get_nodes_in_group("Enemy")
		for enemy in EnemyArrayLocal:
			if (enemy == raycast.get_collider()) && (enemy.HitPoints <= 0):
				pull_state = false
				clinch_state = false
				grab_punch_state = false
				grab_idle_transition_state = true
				timer_grab_punch.stop()
				animation.play("Grab_punch_idle_transition")


func grab_punch_idle_transition():
	
	grab_idle_transition_state = false


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


func get_hurt():
	
	if (successfull_parry == false) && (Global_variables_functions.enemy_attack_hit == true):
		Global_variables_functions.enemy_attack_hit = false
		#print ("Player Hurt")
		HitPoints -= damage_per_hit


func buffer():
	
	if (timer_attack.is_stopped() == false) || (timer_block.is_stopped() == false) || (timer_grab.is_stopped() == false) || (timer_grab_punch.is_stopped() == false) || (timer_dash.is_stopped() == false) || (timer_attack_charge.is_stopped() == false) || (animation.current_animation == "Power_attack_release_L") || (animation.current_animation == "Power_attack_release_R"):
		
		if(Input.is_action_just_pressed("attack")):
			
			if (clinch_state == false):
				#print("ATTACK")
				nr += 1
				last_action = "attack"
			else:
				#print("GRAB_PUNCH", nr)
				nr += 1
				last_action = "grab_punch"
			
		if(Input.is_action_just_pressed("block")):
			#print("BLOCK")
			nr += 1
			last_action = "block"
			
		if(Input.is_action_just_pressed("grab")):
			
			if (clinch_state == false) && (pull_state == false):
				#print("GRAB")
				nr += 1
				last_action = "grab"
			else:
				#print("THROW")
				nr += 1
				last_action = "throw"
		
		if(Input.is_action_just_pressed("dash")):
			nr += 1
			last_action = "dash"


func choose_action_buffer():


	if (last_action == "attack"):
		attack_buffer()
		last_action_release = "attack"
		print("Attack buffer")
		
	if (last_action == "block"):
		block_buffer()
		#print("Block buffer")
		
	if (last_action == "grab"):
		grab_buffer()
	
	if (last_action == "grab_punch"):
		grab_punch_buffer()
	
	if (last_action == "throw"):
		throw_buffer()
	
	if (last_action == "dash"):
		dash_seq()
		#print("Dash buffer")
	
	last_action = "new"
	nr = 0


func comboVariety(action_name):
	
	action_array[index_ac_arr] = action_name
	index_ac_arr += 1
	
	if (index_ac_arr >= action_array.size()):
		index_ac_arr = 0
		
	##################################################
	
	for i in range(0, action_array.size()):
		for j in range(0, action_array.size()):
			if (fr[i] == action_array[j]):
				if (variety > 0) && (nr_fr >= 1):
					variety -= 1
					#print("act_arr: ", variety)
				nr_fr += 1
		nr_fr = 0
	
	if (parry_ok == true) && ((action_name == "attackR") || (action_name == "attackL") || (action_name == "grab_punch")):
		parry_ok = false
		damage = damage_base * variety + parry_hit_damage
		#print("PARRY_HIT")
	else:
		damage = damage_base * variety
		
	#print(action_array)
	#print(damage)
	#print(action_array.size())
	variety_for_text = variety
	variety = action_array.size()
	
	##################################################


##########################-----Areas-------###############################


func _on_area_parry_2d_area_entered(area: Area2D) -> void:
	#if(area.name == EnemyArray[1].name):
	block_detection = true
	enemy_area_ID = area
	#print("block detection")
	#print("Player detection: ", area)


func _on_area_parry_2d_area_exited(area: Area2D) -> void:
	#if(area.name == EnemyArray[1].name):
	block_detection = false


#########################------Timers-------####################################


func _on_timer_timeout() -> void:
	
	attack_state = false
	hand_right.monitoring = false
	hand_left.monitoring = false
	
	choose_action_buffer()
	attack_charge()


func _on_timer_attack_hit_timeout() -> void:
	
	if (raycast.is_colliding()):
		enemy_body_ID = raycast.get_collider()
		attack_connection = true
		#print(enemy_body_ID)
		if (right_left_hand == true):
			comboVariety("attackL")
		else:
			comboVariety("attackR")	
		#print(combo_metter)
	else:
		attack_connection = false


func _on_timer_block_timeout() -> void:
	
	block_state = false
	successfull_parry = false
	
	choose_action_buffer()


func _on_timer_grab_timeout() -> void:
	
	grab_state = false
	choose_action_buffer()


func _on_timer_grab_connected_timeout() -> void:
	
	if (raycast.is_colliding()):
		enemy_raycast_collided = raycast.get_collider()
		grab_state = false
		pull_state = true
		comboVariety("grab")
		timer_grab.stop()
		animation.play("Pull")
		timer_pull.start(0.5)
		#print("Grab HIT")


func _on_timer_pull_timeout() -> void:
	
	pull_state = false
	clinch_state = true
	animation.play("Clinch")


func _on_timer_throw_timeout() -> void:
	
	throw_state = false
	enemy_raycast_collided = null


func _on_timer_grab_punch_timeout() -> void:
	
	grab_punch_state = false
	
	if (raycast.is_colliding()):
		enemy_body_ID = raycast.get_collider()
		attack_connection = true
		comboVariety("grab_punch")
		
	else:
		attack_connection = false

	choose_action_buffer()


func _on_timer_dash_timeout() -> void:
	
	dash_state = false
	AKBS.monitorable = false
	choose_action_buffer()


func _on_timer_dash_recovery_timeout() -> void:
	
	dash_nr += 1
	#print("dash_nr + 1: ", dash_nr)
	
	if (dash_nr >= 2):
		#print("dash recovered")
		timer_dash_recovery.stop()
	else:
		timer_dash_recovery.start(1)


func _on_timer_iframes_timeout() -> void:
	
	self.set_collision_layer_value(1, true)
	self.set_collision_mask_value(1, true)
	self.set_collision_layer_value(8, false)
	self.set_collision_mask_value(8, false)


func _on_timer_attack_charge_timeout() -> void:
	pass
