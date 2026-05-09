extends CharacterBody3D

@export var speed = 30
@export var gravity = 9.8
@export var damage = 20

@onready var animation = $AnimationPlayer
@onready var collision_shape = $CollisionShape3D

###############################################################

@onready var timer_general_states = $Timer_general_states

##############################################################

enum State {
	IDLE,
	MOVE,
	ATTACK,
	HURT,
	PARRIED,
	PARRIED_COUNTERED,
	CLINCHED,
	THROWN,
	CLINCHED_HIT
}

var current_state: State = State.IDLE
var already_hit = false
var hit_flag_on_player = false
var attack_zone = false
var area_attack_range = false
var attack_hit_connection = false
var player


func _ready():
	
	player = get_tree().get_first_node_in_group("Player_3D")
	Global_3D.enemy_array.push_front(self)


func _physics_process(delta):

	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	#enemy_behaviour(delta)
	enemy_behaviour_NEW(delta)
	
	if current_state != State.CLINCHED:
		move_and_slide()


###########################################################


func enemy_behaviour_NEW(delta):
	
	handle_state(delta)


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
		State.PARRIED:
			_parried_state()
		State.PARRIED_COUNTERED:
			_parried_countered_state()
		State.CLINCHED:
			_clinched_state()
		State.THROWN:
			_thrown_state()
		State.CLINCHED_HIT:
			_clinched_hit_state()


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
		State.PARRIED:
			print("ENEMY: Enter Parried")
		State.PARRIED_COUNTERED:
			print("ENEMY: Enter Parried Countered")
		State.CLINCHED:
			velocity = Vector3.ZERO
			collision_shape.disabled = true
			print("ENEMY: Enter Clinched")
		State.THROWN:
			print("ENEMY: Enter Thrown")
		State.CLINCHED_HIT:
			print("ENEMY: Enter Clinched Hit")


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
		State.PARRIED:
			print("ENEMY: Exit Parried")
		State.PARRIED_COUNTERED:
			print("ENEMY: Exit Parried Countered")
		State.CLINCHED:
			collision_shape.disabled = false
			print("ENEMY: Exit Clinched")
		State.THROWN:
			print("ENEMY: Exit Thrown")
		State.CLINCHED_HIT:
			print("ENEMY: Exit Clinched Hit")


####################################################


func _idle_state():
	
	velocity = Vector3.ZERO
	animation.play("Idle")
	
	look_at(player.global_position)
	
	if (attack_zone == false):
		change_state(State.MOVE)
	
	if (timer_general_states.is_stopped() == true) && (attack_zone == true):
		timer_general_states.start(1)
	
	if (self == player.enemy_body_ID) && (player.attack_damage_condition == true) && (self.already_hit == false):
		change_state(State.HURT)
	
	if (self == player.enemy_body_ID) && (player.grab_condition == true):
		change_state(State.CLINCHED)


func _move_state():
	
	var direction = (player.global_position - global_position).normalized()
	
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	
	look_at(player.global_position)
	
	animation.play("Move")
	
	if (attack_zone == true):
		animation.stop(true)
		timer_general_states.stop()
		change_state(State.ATTACK)
	
	if (self == player.enemy_body_ID) && (player.attack_damage_condition == true) && (self.already_hit == false):
		change_state(State.HURT)
	
	if (self == player.enemy_body_ID) && (player.grab_condition == true):
		change_state(State.CLINCHED)


func _attack_state():
	
	velocity.x = 0
	velocity.z = 0
	
	if (timer_general_states.is_stopped() == true):
		animation.play("Attack")
		timer_general_states.start(animation.current_animation_length)
	
	attack_impact()
		
	if (self == player.enemy_body_ID) && (player.attack_damage_condition == true) && (self.already_hit == false): 
		timer_general_states.stop()
		change_state(State.HURT)
	
	if (self == player.enemy_body_ID) && (player.grab_condition == true):
		change_state(State.CLINCHED)


func attack_impact():
	
	if (timer_general_states.time_left < 0.3) && (timer_general_states.time_left > 0.2) && (area_attack_range == true): 
		attack_hit_connection = true
		
		if  (player.BPS == true):
			player.BPS = false
			timer_general_states.stop()
			change_state(State.PARRIED)
	else:
		attack_hit_connection = false


func _hurt_state():
	
	if (timer_general_states.is_stopped()):
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
		change_state(State.CLINCHED)


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
		change_state(State.CLINCHED)


func _parried_countered_state():
	
	if (timer_general_states.is_stopped()):
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
		change_state(State.CLINCHED)


func _clinched_state():
	
	velocity = Vector3.ZERO
	animation.play("Clinch")

	global_position = Vector3(
		player.GrabMarker.global_position.x, 
		0, 
		player.GrabMarker.global_position.z
	)

	var look_target = player.global_position
	look_target.y = global_position.y
	look_at(look_target, Vector3.UP)
	
	if (player.current_state == player.State.GRAB_THROW):
		change_state(State.THROWN)
	
	if player.grab_punch_damage_condition == true:
		player.grab_punch_damage_condition = false
		change_state(State.CLINCHED_HIT)


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
		animation.stop(true)
		animation.play("Clinch_hit")
		timer_general_states.start(animation.current_animation_length)
	
	if (player.current_state == player.State.GRAB_THROW):
		timer_general_states.stop()
		change_state(State.THROWN)


func _thrown_state():
	
	var direction = (global_position - player.global_position).normalized()
	velocity.x = direction.x * speed  
	velocity.z = direction.z * speed
	
	if (timer_general_states.is_stopped()):
		animation.play("Thrown")
		timer_general_states.start(animation.current_animation_length)


#####################################################


func _on_timer_general_states_timeout() -> void:
	
	if (animation.current_animation == "Attack"):
		change_state(State.IDLE)
		
	if (animation.current_animation == "Idle"):
		change_state(State.ATTACK)
	
	if (animation.current_animation == "GettingHurt"):
		change_state(State.IDLE)
		
	if (animation.current_animation == "Parried"):
		change_state(State.IDLE)
	
	if (animation.current_animation == "GettingCountered"):
		change_state(State.IDLE)
	
	if (animation.current_animation == "Thrown"):
		change_state(State.IDLE)
	
	if (animation.current_animation == "Clinch_hit"):
		change_state(State.CLINCHED)


###########################--AREAS_ZONES_BEHAVIOUR--###########################


func _on_area_attack_zone_body_entered(body: Node3D) -> void:
	
	if (body == player):
		attack_zone = true
		print("attack_zone: ", attack_zone)


func _on_area_attack_zone_body_exited(body: Node3D) -> void:
	
	if (body == player):
		attack_zone = false
		print("attack_zone: ", attack_zone)


##############################--AREA_EFFECTS--#################################


func _on_area_attack_range_body_entered(body: Node3D) -> void:
	
	if (body == player):
		area_attack_range = true
		print("area_attack_range: ", area_attack_range)


func _on_area_attack_range_body_exited(body: Node3D) -> void:
	
	if (body == player):
		area_attack_range = false
		print("area_attack_range: ", area_attack_range)
