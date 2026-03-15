extends CharacterBody3D

@export var speed = 30
@export var gravity = 9.8

@onready var animation = $AnimationPlayer

@onready var timer_attack_moment = $Timer_attack_moment


var attack_zone = false
var attack_state = false

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
	
	if (attack_zone == false):
		move(delta)
		if (!timer_attack_moment.is_stopped()):
			timer_attack_moment.stop()
		
		
	if (attack_zone == true):
		
		velocity = Vector3.ZERO
		
		if (attack_state == false):
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
	
	attack_state = true
	velocity = Vector3.ZERO
	animation.play("Attack")


func attack_timeout():
	
	attack_state = false





###########################AREAS###################


func _on_area_attack_zone_body_entered(body: Node3D) -> void:
	
	if (body == player):
		attack_zone = true
		print("attack_zone: ", attack_zone)


func _on_area_attack_zone_body_exited(body: Node3D) -> void:
	
	if (body == player):
		attack_zone = false
		print("attack_zone: ", attack_zone)

##########################TIMERS#####################


func _on_timer_attack_moment_timeout() -> void:
	
	attack()
