extends Node3D

var timer_enemy_behavior: Timer
var player_position_3D: Vector3
var attack_connected = false
var enemy_array = []
var enemies_ready_attack = [] 
var enemies_around_player = []
var x_coord = 0
var z_coord = -2


func _ready() -> void:
	
	create_timer()


func create_enemy_positions_around_player():
	pass


func _physics_process(delta: float) -> void:
	
	for enemy in enemy_array:      
		
		if (enemy.current_state == enemy.State.IDLE): #IDLE EXIT CONDITIONS
			
			if (enemy.attack_zone == false):
				enemy.change_state(enemy.State.MOVE)
				
			if (enemy == enemy.player.enemy_body_ID) && (enemy.player.attack_damage_condition == true) && (enemy.already_hit == false) && (enemy.player.variety_for_text > 3):
				enemy.timer_general_states.stop()
				enemy.change_state(enemy.State.HURT)
				
			elif (enemy == enemy.player.enemy_body_ID) && (enemy.player.attack_damage_condition == true) && (enemy.already_hit == false) && (enemy.player.variety_for_text <= 3):
				enemy.timer_general_states.stop()
				enemy.change_state(enemy.State.HURT_COUNTER)
				
			if (enemy == enemy.player.enemy_body_ID) && (enemy.player.grab_condition == true):
				enemy.timer_general_states.stop()
				enemy.change_state(enemy.State.CLINCHED)
		
		if (enemy.current_state == enemy.State.MOVE): #MOVE EXIT CONDITIONS
			
			if (enemy == enemy.player.enemy_body_ID) && (enemy.player.attack_damage_condition == true) && (enemy.already_hit == false) && (enemy.player.variety_for_text > 3):
				enemy.timer_general_states.stop()
				enemy.change_state(enemy.State.HURT)
			elif (enemy == enemy.player.enemy_body_ID) && (enemy.player.attack_damage_condition == true) && (enemy.already_hit == false) && (enemy.player.variety_for_text <= 3):
				enemy.timer_general_states.stop()
				enemy.change_state(enemy.State.HURT_COUNTER)
			
			if (enemy == enemy.player.enemy_body_ID) && (enemy.player.grab_condition == true):
				enemy.timer_general_states.stop()
				enemy.change_state(enemy.State.CLINCHED)
			
			if (enemy.attack_zone == true):
				enemy.change_state(enemy.State.IDLE)
				
		if (enemy.current_state == enemy.State.ATTACK):  #ATTACK EXIT CONDITIONS
			
			if (enemy == enemy.player.enemy_body_ID) && (enemy.player.attack_damage_condition == true) && (enemy.already_hit == false) && (enemy.player.variety_for_text > 3):
				enemy.timer_general_states.stop()
				enemy.change_state(enemy.State.HURT)
			elif (enemy == enemy.player.enemy_body_ID) && (enemy.player.attack_damage_condition == true) && (enemy.already_hit == false) && (enemy.player.variety_for_text <= 3):
				enemy.timer_general_states.stop()
				enemy.change_state(enemy.State.HURT_COUNTER)
			
			if (enemy == enemy.player.enemy_body_ID) && (enemy.player.grab_condition == true):
				enemy.timer_general_states.stop()
				enemy.change_state(enemy.State.CLINCHED)
			
			
	if enemies_ready_attack:
		if (timer_enemy_behavior.is_stopped()):
			timer_enemy_behavior.start(randf_range(1,2))
	else:
		timer_enemy_behavior.stop()


func create_timer():
	
	timer_enemy_behavior = Timer.new()
	timer_enemy_behavior.one_shot = true
	add_child(timer_enemy_behavior)
	timer_enemy_behavior.timeout.connect(_on_enemy_behavior_timer_timeout)


func _on_enemy_behavior_timer_timeout():
	
	var enemy_attacking = enemies_ready_attack[randi_range(0, enemies_ready_attack.size() - 1)]
	if (enemy_attacking.current_state == enemy_attacking.State.IDLE) || (enemy_attacking.current_state == enemy_attacking.State.MOVE):
		enemy_attacking.animation.stop(true)
		enemy_attacking.timer_general_states.stop()
		enemy_attacking.change_state(enemy_attacking.State.ATTACK)
		print(timer_enemy_behavior.wait_time)
