extends Node3D

var timer_enemy_behavior: Timer
var player_position_3D: Vector3
var attack_connected = false
var enemy_array = []
var enemies_ready_attack = [] 

func _ready() -> void:
	
	create_timer()


func _physics_process(delta: float) -> void:
	
	for enemy in enemy_array:
		if (enemy.attack_zone == false):
			enemy.change_state(enemy.State.MOVE)
	
	if enemies_ready_attack:
		if (timer_enemy_behavior.is_stopped()):
			timer_enemy_behavior.start(randf_range(1,3))
	else:
		timer_enemy_behavior.stop()


func create_timer():
	
	timer_enemy_behavior = Timer.new()
	timer_enemy_behavior.one_shot = true
	add_child(timer_enemy_behavior)
	timer_enemy_behavior.timeout.connect(_on_enemy_behavior_timer_timeout)


func _on_enemy_behavior_timer_timeout():
	
	var enemy_attacking = enemies_ready_attack[randi_range(0, enemies_ready_attack.size() - 1)]
	enemy_attacking.change_state(enemy_attacking.State.ATTACK)
	print(timer_enemy_behavior.wait_time)
