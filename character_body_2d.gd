extends CharacterBody2D

@export var speed = 400
var some_zero: Vector2

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
@onready var marker_hand = $"Hand L/Marker2D"
@onready var areaparry = $AreaParry2D
@onready var raycast = $RayCast2D

var action_buffer = ["1","2","3","4","5","6","7","8","9","10"]
var nr = 0

var attack_state = false
var block_state = false
var grab_state = false
var pull_state = false
var clinch_state = false
var grab_punch_state = false
var throw_state = false
var in_buffer = false
var action_to_block_transition = false
var present_action = "new"
var last_action = "new"
var second_last_action = "new"
var right_left_hand = false
var block_detection = false
var successful_parry = false
var attack_connection = false
var left_click_number = 0
var right_click_number = 0
var grab_button_pressed_number = 0
var successfull_parry = false
var HitPoints = 100
var damage_per_hit = 20
var EnemySquare
var EnemyArray
var enemy_body_ID
var enemy_area_ID
var enemy_raycast_collided


func _ready() -> void:
	EnemySquare = get_tree().get_first_node_in_group("Enemy")
	EnemyArray = get_tree().get_nodes_in_group("Enemy")


func _physics_process(delta: float) -> void:
	
	look_at(get_global_mouse_position())
	move()
	move_and_slide()
	buffer() #it needs to be called before other actions
	attack()
	block()
	grab()
	grab_punch()
	throw()
	get_hurt()
	Global_variables_functions.player_position = get_position()


func move():
	
	var input_direction = Input.get_vector("left", "right", "up", "down")
	some_zero.x = 0
	some_zero.y = 0
	
	velocity = input_direction * speed
	
	if (input_direction) && (attack_state == false) && (block_state == false) && (grab_state == false) && (pull_state == false) && (clinch_state == false) && (throw_state == false):
		animation.play("Move")
	elif (input_direction == some_zero) && (attack_state == false) && (block_state == false) && (grab_state == false) && (pull_state == false) && (clinch_state == false) && (throw_state == false):
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


func attack():
	
	if (Input.is_action_just_pressed("attack")) && (attack_state == false) && (block_state == false) && (grab_state == false) && (pull_state == false) && (clinch_state == false) && (throw_state == false):
		attack_seq() 
	if (Input.is_action_just_pressed("attack")):
		left_click_number = left_click_number + 1
		right_click_number = 0
		grab_button_pressed_number = 0


func attack_buffer():
	
	if (block_state == false):
		attack_seq()


func block_seq():
	
	block_state = true
	
	if (attack_state == true) || (grab_state == true):
		action_to_block_transition = true
	
	attack_state = false
	grab_state = false
	pull_state = false
	clinch_state = false
	throw_state = false
	enemy_raycast_collided = null
	timer_pull.stop()
	animation.stop()
	animation.play("Block")
	timer_attack.stop()
	timer_attack_connected.stop()
	timer_grab.stop()
	timer_block.start(0.5)
	
	
func block():
	
	if(Input.is_action_just_pressed("block")) && (block_state == false):
		hand_right.monitoring = false
		hand_left.monitoring = false
		areaparry.monitoring = true
		block_seq()

	if (Input.is_action_just_pressed("block")):
		right_click_number = right_click_number + 1
		left_click_number = 0
		grab_button_pressed_number = 0


func block_buffer():
	
	block_seq()


func grab_seq():
	
	grab_state = true
	animation.play("Grab")
	timer_grab.start(0.5)
	timer_grab_connected.start(0.23)
	

func grab():
	
	if (Input.is_action_just_pressed("grab")) && (block_state == false) && (attack_state == false) && (grab_state == false) && (pull_state == false) && (clinch_state == false) && (throw_state == false):
		grab_seq()
		
	if (Input.is_action_just_pressed("grab")):
		grab_button_pressed_number += 1
		left_click_number = 0
		right_click_number = 0
		

func grab_buffer():
	
	if (block_state == false):
		grab_seq()


func grab_punch():
	
	if (Input.is_action_just_pressed("attack")) && (clinch_state == true) && (grab_punch_state == false):
		grab_punch_state = true
		animation.play("Grab_punch")
		timer_grab_punch.start(0.5)
	
	if (Input.is_action_just_pressed("attack")) && (pull_state == true) && (grab_punch_state == false):
		grab_punch_state = true
		animation.play("Grab_punch")
		timer_grab_punch.start(0.5)
		timer_pull.stop()
		
func grab_punch_buffer():
	
	grab_punch_state = true
	animation.play("Grab_punch")
	timer_grab_punch.start(0.5)


func throw():
	
	if (Input.is_action_just_pressed("grab")) && ((pull_state == true) || (clinch_state == true)):
		pull_state = false
		clinch_state = false
		throw_state = true
		timer_pull.stop()
		animation.play("Throw")
		timer_throw.start(0.3)


func get_hurt():
	
	if (successfull_parry == false) && (Global_variables_functions.enemy_attack_hit == true):
		Global_variables_functions.enemy_attack_hit = false
		print ("Player Hurt")
		HitPoints -= damage_per_hit


func buffer():
	
	if (timer_attack.is_stopped() == false) || (timer_block.is_stopped() == false) || (timer_grab.is_stopped() == false):
		if(Input.is_action_just_pressed("attack")):
			
			if (clinch_state == false):
				print("ATTACK")
				nr += 1
				last_action = "attack"
			else:
				nr += 1
				last_action = "grab_punch"
			
		if(Input.is_action_just_pressed("block")):
			print("BLOCK")
			nr += 1
			last_action = "block"
			
		if(Input.is_action_just_pressed("grab")):
			print("GRAB")
			nr += 1
			last_action = "grab"
	
	
func choose_action_buffer():
	
	if (last_action == "attack"):
		attack_buffer()
	
	if (last_action == "block") && (action_to_block_transition == true) && (nr < 2):
		action_to_block_transition = false
	elif (last_action == "block"):
		block_buffer()
		
	if (last_action == "grab"):
		grab_buffer()
	
	if (last_action == "grab_punch"):
		grab_punch_buffer()
	
	last_action = "new"
	nr = 0
	
	
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


func _on_timer_attack_hit_timeout() -> void:
	
	if (raycast.is_colliding()):
		enemy_body_ID = raycast.get_collider()
		attack_connection = true
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
		timer_grab.stop()
		animation.play("Pull")
		timer_pull.start(0.5)
		print("Grab HIT")


func _on_timer_pull_timeout() -> void:
	
	pull_state = false
	clinch_state = true
	animation.play("Clinch")
	

func _on_timer_throw_timeout() -> void:
	throw_state = false
	enemy_raycast_collided = null


func _on_timer_grab_punch_timeout() -> void:
	
	grab_punch_state = false
