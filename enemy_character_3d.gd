extends CharacterBody3D

@export var speed = 30
@export var gravity = 9.8
@export var damage = 20

@onready var animation = $AnimationPlayer

@onready var timer_attack_moment = $Timer_attack_moment
@onready var timer_attack_timeout = $Timer_attack_timeout
@onready var timer_attack_impact = $Timer_attack_impact
@onready var timer_parried = $Timer_parried
@onready var timer_parried_countered = $Timer_parried_countered
@onready var timer_hurt = $Timer_hurt

var attack_zone = false
var attack_state = false
var hurt_state = false
var parried_state = false
var area_attack_range = false
var attack_hit_connection = false
var attack_hit_blocked_parried = false
var attack_parry_connection = false
var attack_hit_perfect_parried = false
var attack_hit_blocked = false
var player

@onready var timer_general_states = $Timer_general_states

enum State {
	IDLE,
	MOVE,
	ATTACK,
	HURT,
	PARRIED,
	PARRIED_COUNTERED
}

var current_state: State = State.IDLE
var already_hit = false
var hit_flag_on_player = false


func _ready():
	
	player = get_tree().get_first_node_in_group("Player_3D")
	Global_3D.enemy_array.push_front(self)


func _physics_process(delta):

	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	#enemy_behaviour(delta)
	enemy_behaviour_NEW(delta)
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
			print("ENEMY: Parried Countered")


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
			print("ENEMY: Parried Countered")


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


func attack_impact():
	
	if (timer_general_states.time_left < 0.3) && (timer_general_states.time_left > 0.2) && (attack_zone == true): 
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


func _parried_countered_state():
	
	if (timer_general_states.is_stopped()):
		already_hit = true
		velocity.x = 0
		velocity.z = 0
		animation.play("GettingCountered")
		timer_general_states.start(animation.current_animation_length)
	
	if (self == player.enemy_body_ID) && (player.attack_damage_condition == true) && (self.already_hit == false): 
		change_state(State.HURT)


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


#######################################################


func enemy_behaviour(delta):
	
	getHurt()
	
	if (attack_zone == false) && (hurt_state == false) && (parried_state == false):  #####___MOVEMENT_ZONE___######
		move(delta)
		if (!timer_attack_moment.is_stopped()):
			timer_attack_moment.stop()
		
	if (attack_zone == true) && (hurt_state == false):  #####___ATTACK_ZONE___#########
		
		velocity = Vector3.ZERO
		
		if (attack_state == false) && (parried_state == false):
			animation.play("Idle")
		
		if (timer_attack_moment.is_stopped()):
			timer_attack_moment.start(1)


func move(delta):
	
	if (attack_state == false):
		
		if not is_on_floor():
			velocity.y -= gravity * delta
		
		if player:
			var direction = player.global_transform.origin - global_transform.origin
			direction.y = 0
			direction = direction.normalized()
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			look_at(player.global_transform.origin, Vector3.UP)
		
			animation.play("Move")


func attack():
	
	if (parried_state == false):
		attack_state = true
		velocity = Vector3.ZERO
		animation.play("Attack")
		timer_attack_timeout.start(0.833)
		timer_attack_impact.start(0.5)


func parried():
	
	if (attack_state == true):
		attack_state = false
		parried_state = true
		timer_attack_timeout.stop()
		animation.play("Parried")
		timer_parried.start(0.833)


func getHurt():
	
	if (player.raycastcolis == true) && (self == player.enemy_body_ID) && (parried_state == false):
		velocity = Vector3.ZERO
		hurt_state = true
		attack_state = false
		timer_attack_moment.stop()
		timer_hurt.start(0.833)
		animation.stop(true)
		animation.play("GettingHurt")
		
	elif (player.raycastcolis == true) && (self == player.enemy_body_ID) && (parried_state == true): 
		velocity = Vector3.ZERO
		hurt_state = true
		attack_state = false
		parried_state = false
		timer_parried.stop()
		timer_attack_moment.stop()
		animation.play("GettingCountered")
		timer_parried_countered.start(animation.current_animation_length)


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


#############################--TIMERS_STATES--#################################


func _on_timer_attack_timeout_timeout() -> void:
	
	attack_state = false


func _on_timer_attack_impact_timeout() -> void:
	
	if (area_attack_range == true) && (player.block_state == false) && (player.block_hold_state == false) && (player.block_parriable_state == false) && (player.perfect_block_state == false):
		print("ENEMY HIT CONNECTED")
		attack_hit_connection = true
	
	elif (area_attack_range == true) && ((player.block_state == true) || (player.block_hold_state == true)) && (player.block_parriable_state == false):
		print("HITBlocked")
		attack_hit_blocked = true

	elif (area_attack_range == true) && (player.block_state == false) && (player.block_hold_state == false) && (player.block_parriable_state == true) && (player.perfect_block_state == false):
		print("HITParried")
		attack_hit_blocked_parried = true
	
	elif (area_attack_range == true) && (player.block_state == false) && (player.block_hold_state == false) && (player.block_parriable_state == true) && (player.perfect_block_state == true):  
		print("PERFECT_PARRIED")
		attack_hit_perfect_parried = true
		parried()


func _on_timer_parried_timeout() -> void:
	
	parried_state = false


func _on_timer_parried_countered_timeout() -> void:
	
	hurt_state = false


##########################--TIMERS_MOMENT_BEHAVIOUR--##########################


func _on_timer_attack_moment_timeout() -> void:
	
	attack()


func _on_timer_hurt_timeout() -> void:
	hurt_state = false
	print("ENDED HURT")
