extends Node3D

var enemy = preload("res://EnemyCharacter_3D.tscn")
var nr = 0
var pos: Vector3
#@onready var Enemy  = get_tree().get_nodes_in_group("Enemy_3D") 


func _ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	
	if (nr < 0):
		inst()
		nr += 1
	
	if (Input.is_action_just_pressed("respawn enemies")):
		inst()
		print(Global_3D.enemy_array)


func inst():
	var instance = enemy.instantiate()
	pos = Vector3 (-50, 0, -50)
	instance.position = pos
	add_child(instance)
