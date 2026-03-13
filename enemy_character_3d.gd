extends CharacterBody3D

@export var speed = 30
@export var gravity = 9.8

@onready var animation = $AnimationPlayer

var attack_zone = false
var attack_state = false

var player

func _ready():
	player = get_tree().get_first_node_in_group("Player_3D")


func _physics_process(delta):

	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	move(delta)
	attack()
	move_and_slide()



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
	
	if (attack_state == true):
		velocity = Vector3.ZERO
		animation.play("Attack")


func attack_timeout():
	
	attack_state = false
	speed = 30


###########################AREAS###################


func _on_area_attack_zone_body_entered(body: Node3D) -> void:
	
	if (body == player):
		attack_state = true
