extends CharacterBody3D

@export var speed = 30
@export var gravity = 9.8

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
var attack_parry_connection = false
var player


func _ready():
	player = get_tree().get_first_node_in_group("Player_3D")


func _physics_process(delta):

	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	enemy_behaviour(delta)
	
	move_and_slide()


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
	
	if (player.attack_connection == true) && (self == player.enemy_body_ID) && (parried_state == false):
		player.attack_connection = false
		velocity = Vector3.ZERO
		hurt_state = true
		attack_state = false
		timer_attack_moment.stop()
		timer_hurt.start(0.8)
		animation.play("GettingHurt")
		
	elif (player.attack_connection == true) && (self == player.enemy_body_ID) && (parried_state == true):
		player.attack_connection = false
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
	
	if (area_attack_range == true) && (player.block_parriable_state == false):
		print("HIT")
	elif (area_attack_range == true) && (player.block_parriable_state == true):
		print("HITParried")
		attack_parry_connection = true
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
