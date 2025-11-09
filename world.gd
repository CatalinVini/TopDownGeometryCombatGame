extends Node2D

var enemy = preload("res://EnemyCharacter.tscn")
var nr = 0
var pos: Vector2
@onready var Enemy  = get_tree().get_nodes_in_group("Enemy") 

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if (nr < 1):
		inst()
		nr += 1
		
func inst():
	var instance = enemy.instantiate()
	pos = Vector2(-300,-300)
	instance.position = pos
	add_child(instance)
	
	
