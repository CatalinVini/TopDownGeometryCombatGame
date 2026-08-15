extends CharacterBody3D

@export var speed = 30
@export var gravity = 9.8
@export var damage = 20
@export var HP = 100

@onready var animation = $AnimationPlayer
@onready var collision_shape = $CollisionShape3D
@onready var AreaScanForPush = $AreaScanForPush/CollisionShape3D
@onready var AreaToBeDetectedPush = $AreaToBeDetectedPush/CollisionShape3D
@onready var AreaAttackZone = $AreaAttackZone/CollisionShape3D
@onready var nav_agent = $NavigationAgent3D

###############################################################

@onready var timer_general_states = $Timer_general_states
@onready var timer_HP_visible = $Timer_HP_visible
@onready var timer_distancing = $Timer_distancing
@onready var timer_clinch_attack = $Timer_clinch_attack

##############################################################

enum State {
	
	IDLE,
	MOVE,
	ATTACK,
	HURT,
	HURT_COUNTER,
	PUSHED,
	PARRIED,
	PARRIED_COUNTERED,
	CLINCHED,
	CLINCHED_STUNNED,
	CLINCHED_HIT,
	CLINCHED_STUNNED_HIT,
	CLINCHED_ATTACK,
	THROWN,
	DEATH
}

var current_state: State = State.IDLE
var already_hit = false
var hit_flag_on_player = false
var attack_zone = false
var area_attack_range = false
var attack_hit_connection = false
var HP_visible = false
var pushed_location
var player


func _ready():
	
	player = get_tree().get_first_node_in_group("Player_3D")
	Enemy_Behavior.enemy_array.push_back(self)
	
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 1.5
	nav_agent.avoidance_enabled = true
	nav_agent.radius = 0.6
	
	timer_distancing.autostart = true


func _physics_process(delta):

	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	#enemy_behaviour(delta)
	enemy_behaviour_NEW(delta)
	
	if current_state != State.CLINCHED_STUNNED:
		move_and_slide()


###########################################################


func enemy_behaviour_NEW(delta):
	
	handle_state(delta)


func TakeDamage():
	
	timer_HP_visible.start(1.5) 
	HP_visible = true
	
	if (HP - player.damage > 0):
		HP = HP - player.damage
	elif (HP - player.damage <= 0):
		HP = 0
		timer_general_states.stop()
		change_state(State.DEATH)
		return 1


func fallow_path() -> void:
	
	if nav_agent.is_navigation_finished():
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var next_position = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_position)

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	if direction.length() > 0.1:
		look_at(Vector3(next_position.x, global_position.y, next_position.z), Vector3.UP)


func parried_condition():
	
	if (player.B_simple_parried == true):
		player.B_simple_parried = false
	
	if (player.B_timed_parry == true):
		player.B_timed_parry = false
	
	if (player.BPS == true):
		player.BPS = false
		timer_general_states.stop()
		change_state(State.PARRIED)
	
	if  (player.BPS_grab == true):
		player.BPS_grab = false
		timer_general_states.stop()
		timer_general_states.timeout.emit()
		
	if (player.B_timed_parry_grab == true):
		player.B_timed_parry_grab = false
		timer_general_states.stop()
		timer_general_states.timeout.emit()


############################################################


func handle_state(delta):
	
	match current_state:
		State.IDLE:
			_idle_state()
		State.MOVE:
			_move_state()
		State.ATTACK:
			_attack_state()
		State.HURT:
			_hurt_state()
		State.HURT_COUNTER:
			_hurt_counter_state()
		State.PUSHED:
			_pushed_state()
		State.PARRIED:
			_parried_state()
		State.PARRIED_COUNTERED:
			_parried_countered_state()
		State.CLINCHED:
			_clinched_state()
		State.CLINCHED_STUNNED:
			_clinched_stunned_state()
		State.CLINCHED_HIT:
			_clinched_hit_state()
		State.CLINCHED_STUNNED_HIT:
			_clinched_stunned_hit_state()
		State.CLINCHED_ATTACK:
			_clinched_attack_state()
		State.THROWN:
			_thrown_state()
		State.DEATH:
			_death_state()


func change_state(new_state: State):
	
	if current_state == new_state:
		return
	
	exit_state(current_state)
	current_state = new_state
	enter_state(new_state)


func enter_state(state):
	
	match state:
		State.IDLE:
			print("ENEMY: Enter Idle")
		State.MOVE:
			print("ENEMY: Enter Move")
		State.ATTACK:
			print("ENEMY: Enter Attack")
		State.HURT:
			print("ENEMY: Enter Hurt")
		State.HURT_COUNTER:
			print("ENEMY: Enter Hurt_Counter")
		State.PUSHED:
			print("ENEMY: Enter Pushed")
		State.PARRIED:
			print("ENEMY: Enter Parried")
		State.PARRIED_COUNTERED:
			print("ENEMY: Enter Parried Countered")
		State.CLINCHED:
			print("ENEMY: Enter Clinched_State")
		State.CLINCHED_STUNNED:
			velocity = Vector3.ZERO
			print("ENEMY: Enter Clinched_Stunned")
		State.CLINCHED_HIT:
			print("ENEMY: Enter Clinched_Hit")
		State.CLINCHED_STUNNED_HIT:
			print("ENEMY: Enter Clinched_Stunned_Hit")
		State.CLINCHED_ATTACK:
			print("ENEMY: Enter Clinched_Attack")
		State.THROWN:
			AreaScanForPush.disabled = true
			AreaToBeDetectedPush.disabled = false
			print("ENEMY: Enter Thrown")
		State.DEATH:
			print("ENEMY: Enter Death")


func exit_state(state):
	
	match state:
		State.IDLE:
			print("ENEMY: Exit Idle")
		State.MOVE:
			print("ENEMY: Exit Move")
		State.ATTACK:
			print("ENEMY: Exit Attack")
			attack_hit_connection = false
			hit_flag_on_player = false
		State.HURT:
			print("ENEMY: Exit Hurt")
		State.HURT_COUNTER:
			attack_hit_connection = false
			hit_flag_on_player = false
			print("ENEMY: Exit Hurt Counter")
		State.PUSHED:
			print("ENEMY: Exit Pushed")
		State.PARRIED:
			print("ENEMY: Exit Parried")
		State.PARRIED_COUNTERED:
			print("ENEMY: Exit Parried Countered")
		State.CLINCHED:
			print("ENEMY: Enter Clinched")
		State.CLINCHED_STUNNED:
			print("ENEMY: Exit Clinched_Stunned")
		State.CLINCHED_HIT:
			attack_hit_connection = false
			hit_flag_on_player = false
			print("ENEMY: Enter Clinched_Hit")
		State.CLINCHED_STUNNED_HIT:
			print("ENEMY: Exit Clinched_Stunned_Hit")
		State.CLINCHED_ATTACK:
			attack_hit_connection = false
			hit_flag_on_player = false
			print("ENEMY: Exit Clinched_Attack")
		State.THROWN:
			print("ENEMY: Exit Thrown")
		State.DEATH:
			print("ENEMY: Exit Death")


####################################################


func _idle_state():
	
	velocity = Vector3.ZERO
	animation.play("Idle_Aggresive", 0.5)
	
	look_at(player.global_position)


func _move_state():
	
	nav_agent.target_position = player.global_position
	fallow_path()
	
	animation.play("Move_Run", 0.5)


func _attack_state():
	
	velocity.x = 0
	velocity.z = 0
	
	if (timer_general_states.is_stopped() == true):
		animation.play("Attack_Short1")
		timer_general_states.start(animation.current_animation_length)
	
	attack_impact()


func attack_impact():
	
	if (animation.current_animation == "Attack_Short1") && (timer_general_states.time_left < 0.3) && (timer_general_states.time_left > 0.2) && (area_attack_range == true): 
		attack_hit_connection = true
		parried_condition()
	
	elif (animation.current_animation == "GettingHurtAndCounter_1") && (timer_general_states.time_left < 0.2) && (timer_general_states.time_left > 0.1) && (area_attack_range == true):
		attack_hit_connection = true
		parried_condition()
		
	if (animation.current_animation == "Clinch_Attack") && (timer_general_states.time_left < 0.2):
		attack_hit_connection = true
		parried_condition()


func _hurt_state():
	
	if (timer_general_states.is_stopped()):
		if (TakeDamage() == 1):
			return
		self.already_hit = true
		velocity.x = 0
		velocity.z = 0
		animation.stop(true)
		animation.play("GettingHurt")
		timer_general_states.start(animation.current_animation_length)
		
	if (self == player.enemy_body_ID) && (player.attack_damage_condition == true) && (self.already_hit == false): 
		timer_general_states.stop()
		change_state(State.HURT)
	
	if (self == player.enemy_body_ID) && (player.grab_condition == true):
		timer_general_states.stop()
		change_state(State.CLINCHED)


func _hurt_counter_state():
	
	if (timer_general_states.is_stopped() == true):
		if (TakeDamage() == 1):
			return
		self.already_hit = true
		velocity.x = 0
		velocity.z = 0
		animation.stop(true)
		animation.play("GettingHurtAndCounter_1")
		timer_general_states.start(animation.current_animation_length)
	
	attack_impact()
	
	if (self == player.enemy_body_ID) && (player.attack_damage_condition == true) && (self.already_hit == false): 
		timer_general_states.stop()
		change_state(State.HURT)
	
	if (self == player.enemy_body_ID) && (player.grab_condition == true):
		timer_general_states.stop()
		change_state(State.CLINCHED_STUNNED)


func _parried_state():
	
	var direction = (global_position - player.global_position).normalized()
	velocity.x = direction.x * speed/3  
	velocity.z = direction.z * speed/3
	
	if (timer_general_states.is_stopped() == true):
		animation.play("Parried", 0.2)
		timer_general_states.start(animation.current_animation_length)
	
	if (self == player.enemy_body_ID) && (player.attack_damage_condition == true):
		timer_general_states.stop()
		change_state(State.PARRIED_COUNTERED)
	
	if (self == player.enemy_body_ID) && (player.grab_condition == true):
		timer_general_states.stop()
		change_state(State.CLINCHED_STUNNED)


func _parried_countered_state():
	
	if (timer_general_states.is_stopped()):
		if (TakeDamage() == 1):
			return
		already_hit = true
		velocity.x = 0
		velocity.z = 0
		animation.play("GettingCountered")
		timer_general_states.start(animation.current_animation_length)
	
	if (self == player.enemy_body_ID) && (player.attack_damage_condition == true) && (self.already_hit == false): 
		timer_general_states.stop()
		change_state(State.HURT)
	
	if (self == player.enemy_body_ID) && (player.grab_condition == true):
		timer_general_states.stop()
		change_state(State.CLINCHED_STUNNED)


func _pushed_state():
	
	var direction = (global_position - pushed_location).normalized()
	velocity.x = direction.x   
	velocity.z = direction.z  
	
	if (timer_general_states.is_stopped()):
		look_at(pushed_location)
		animation.play("Thrown")
		timer_general_states.start(animation.current_animation_length)
	
	if (self == player.enemy_body_ID) && (player.attack_damage_condition == true) && (self.already_hit == false): 
		timer_general_states.stop()
		change_state(State.HURT)


func _clinched_state():

	velocity = Vector3.ZERO
	animation.play("Clinch_Idle")

	global_position = Vector3(
		player.GrabMarker.global_position.x, 
		0, 
		player.GrabMarker.global_position.z
	)

	var look_target = player.global_position
	look_target.y = global_position.y
	look_at(look_target, Vector3.UP)
	
	if (timer_clinch_attack.is_stopped()):
		timer_clinch_attack.start(randf_range(1,2))
	
	if (player.current_state == player.State.GRAB_THROW):
		timer_general_states.stop()
		change_state(State.THROWN)
	
	if player.grab_punch_damage_condition == true && already_hit == false:
		already_hit = true
		timer_general_states.stop()
		change_state(State.CLINCHED_HIT)


func _clinched_stunned_state():
	
	velocity = Vector3.ZERO
	animation.play("Clinch_Stunned")

	global_position = Vector3(
		player.GrabMarker.global_position.x, 
		0, 
		player.GrabMarker.global_position.z
	)

	var look_target = player.global_position
	look_target.y = global_position.y
	look_at(look_target, Vector3.UP)
	
	if (player.current_state == player.State.GRAB_THROW):
		timer_general_states.stop()
		change_state(State.THROWN)
	
	if player.grab_punch_damage_condition == true && already_hit == false:
		already_hit = true
		timer_general_states.stop()
		change_state(State.CLINCHED_STUNNED_HIT)


func _clinched_hit_state():
	
	velocity = Vector3.ZERO
	
	global_position = Vector3(
		player.GrabMarker.global_position.x, 
		0, 
		player.GrabMarker.global_position.z
	)
	
	var look_target = player.global_position
	look_target.y = global_position.y
	look_at(look_target, Vector3.UP)
	
	if (timer_general_states.is_stopped()):
		if (TakeDamage() == 1):
			return
		already_hit = true
		animation.stop(true)
		animation.play("Clinch_Hit")
		timer_general_states.start(animation.current_animation_length)
	
	if (player.current_state == player.State.GRAB_THROW):
		timer_general_states.stop()
		change_state(State.THROWN)
	
	if player.grab_punch_damage_condition == true && already_hit == false:
		already_hit = true
		timer_general_states.stop()
		change_state(State.CLINCHED_HIT)


func _clinched_stunned_hit_state():
	
	velocity = Vector3.ZERO
	
	global_position = Vector3(
		player.GrabMarker.global_position.x, 
		0, 
		player.GrabMarker.global_position.z
	)
	
	var look_target = player.global_position
	look_target.y = global_position.y
	look_at(look_target, Vector3.UP)
	
	if (timer_general_states.is_stopped()):
		if (TakeDamage() == 1):
			return
		already_hit = true
		animation.stop(true)
		animation.play("Clinch_Stunned_hit")
		timer_general_states.start(animation.current_animation_length)
	
	if (player.current_state == player.State.GRAB_THROW):
		timer_general_states.stop()
		change_state(State.THROWN)
	
	if player.grab_punch_damage_condition == true && already_hit == false:
		already_hit = true
		timer_general_states.stop()
		change_state(State.CLINCHED_STUNNED_HIT)


func _clinched_attack_state():
	
	velocity = Vector3.ZERO
	
	global_position = Vector3(
		player.GrabMarker.global_position.x, 
		0, 
		player.GrabMarker.global_position.z
	)
	
	var look_target = player.global_position
	look_target.y = global_position.y
	look_at(look_target, Vector3.UP)
	
	if (timer_general_states.is_stopped()):
		animation.stop(true)
		animation.play("Clinch_Attack")
		timer_general_states.start(animation.current_animation_length)
		
	attack_impact()
	
	if (player.current_state == player.State.GRAB_THROW):
		timer_general_states.stop()
		change_state(State.THROWN)
		
	if player.grab_punch_damage_condition == true && already_hit == false:
		already_hit = true
		timer_general_states.stop()
		change_state(State.CLINCHED_HIT)


func _thrown_state():
	
	var direction = (global_position - player.global_position).normalized()
	velocity.x = direction.x * speed  
	velocity.z = direction.z * speed
	
	if (timer_general_states.is_stopped()):
		animation.play("Thrown")
		timer_general_states.start(animation.current_animation_length)
	
	if (self == player.enemy_body_ID) && (player.attack_damage_condition == true) && (self.already_hit == false): 
		timer_general_states.stop()
		change_state(State.HURT)


func _death_state():
	
	if (timer_general_states.is_stopped()):
		animation.play("Death")
		timer_general_states.start(animation.current_animation_length)


#####################################################


func _on_timer_general_states_timeout() -> void:
	
	if (current_state == State.ATTACK):
		change_state(State.IDLE)
		return
		
	if (current_state == State.HURT):
		change_state(State.IDLE)
		return
	
	if (current_state == State.HURT_COUNTER):
		change_state(State.IDLE)
		return
	
	if (current_state == State.PUSHED):
		change_state(State.IDLE)
		return
		
	if (current_state == State.PARRIED):
		change_state(State.IDLE)
		return
		
	if (current_state == State.PARRIED_COUNTERED):
		change_state(State.IDLE)
		return
		
	if (current_state == State.THROWN):
		AreaToBeDetectedPush.disabled = true
		AreaScanForPush.disabled = false
		change_state(State.IDLE)
		return
		
	if (current_state == State.CLINCHED_STUNNED_HIT):
		change_state(State.CLINCHED_STUNNED)
		return
	
	if (current_state == State.CLINCHED_HIT):
		change_state(State.CLINCHED)
		return
	
	if (current_state == State.CLINCHED_ATTACK):
		change_state(State.CLINCHED)
		return
	
	if (current_state == State.DEATH):
		Enemy_Behavior.enemy_array.erase(self)
		Enemy_Behavior.enemies_ready_attack.erase(self)
		Enemy_Behavior.enemies_around_player.pop_back()
		print(Enemy_Behavior.enemies_around_player)
		timer_distancing.stop()
		queue_free()


func _on_timer_clinch_attack_timeout() -> void:
	
	if (current_state == State.CLINCHED):
		change_state(State.CLINCHED_ATTACK)
		print("ASDASDADSSADADS")



func _on_timer_hp_visible_timeout() -> void:
	
	HP_visible = false


###########################--AREAS_ZONES_BEHAVIOUR--###########################


func _on_area_attack_zone_body_entered(body: Node3D) -> void:
	
	if (body == player):
		AreaAttackZone.shape.radius = 1.5
		timer_distancing.stop()
		attack_zone = true
		Enemy_Behavior.enemies_ready_attack.push_front(self)
		print("attack_zone: ", attack_zone)


func _on_area_attack_zone_body_exited(body: Node3D) -> void:
	
	if (body == player):
		AreaAttackZone.shape.radius = 1.4
		timer_distancing.start(0.5)
		Enemy_Behavior.enemies_ready_attack.erase(self)
		print("attack_zone: ", attack_zone)


func _on_timer_distancing_timeout() -> void:
	
	attack_zone = false


##############################--AREA_EFFECTS--#################################


func _on_area_attack_range_body_entered(body: Node3D) -> void:
	
	if (body == player):
		area_attack_range = true
		print("area_attack_range: ", area_attack_range)


func _on_area_attack_range_body_exited(body: Node3D) -> void:
	
	if (body == player):
		area_attack_range = false
		print("area_attack_range: ", area_attack_range)


func _on_area_scan_for_push_area_entered(area: Area3D) -> void:
	
	if (area.name == "AreaToBeDetectedPush"):
		pushed_location = area.global_position
		print("PUSHED")
		change_state(State.PUSHED)
