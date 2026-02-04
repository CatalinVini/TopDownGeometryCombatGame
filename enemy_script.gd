extends CharacterBody2D

@export var speed = 0.5
var offset_dif: Vector2
var enemy_position: Vector2
var direction: Vector2
var zero_momentum: Vector2
var player_pos: Vector2
var enemy_pos: Vector2
var retreat_pos: Vector2
var detection = false
var attack_state = false
var retreat_state = false
var hurt_state = false
var parried_state = false
var grabbed_state = false
var thrown_state = false
var enemy_grabbed_canceled_actions = false
var knockback_by_thrown_state = false
var area_detection = false
var area_direction = "."
var attack_connected = false
var attack_area_collided = false
var block_window = false
var attack_hit = false
var death = false
var HitPoints = 100
var attack_damage = 20

@onready var animation = $"../AnimationPlayer"
@onready var enemy_timer_attack = $"../EnemyTimerAttack"
@onready var enemy_timer_hit = $"../EnemyTimerHit"
@onready var enemy_timer_retreat = $"../EnemyTimerRetreat"
@onready var enemy_timer_get_hurt = $"../EnemyTimerGetHurt"
@onready var enemy_timer_knocked_back = $"../EnemyTimerGetKnockedBack"
@onready var enemy_timer_get_parried = $"../EnemyTimerGetParried"
@onready var enemy_timer_thrown = $"../EnemyTimerThrown"
@onready var enemy_timer_visible_HP = $"../EnemyTimerVisibleHP"

@onready var enemy_detection_area2d =  $DetectionArea2D
@onready var Player = get_tree().get_first_node_in_group("Player")
@onready var Player_array = get_tree().get_nodes_in_group("Player")
@onready var path_thrown_backward = $EnemyThrownPath/PathFollow2D
@onready var area_hit_other_enemies = $AreaHitAnotherEnemies
@onready var area_hit_areanw = $AreaNW
@onready var area_hit_areane = $AreaNE
@onready var area_hit_arease = $AreaSE 
@onready var area_hit_areasw = $AreaSW
@onready var knockbackpathse = $KnockBackPathSE/PathFollow2D
@onready var knockbackpathsw = $KnockBackPathSW/PathFollow2D
@onready var knockbackpathnw = $KnockBackPathNW/PathFollow2D
@onready var knockbackpathne = $KnockBackPathNE/PathFollow2D
@onready var canvaslayer = $"../NodeForCanvas"
@onready var progress_bar = $"../NodeForCanvas/Control/ProgressBar"
@onready var ETAMR = $"../EnemyTimerAreasMonitoribleRecovery"

func _ready():
	
	enemy_position.x = 0
	enemy_position.y = 0
	zero_momentum.x = 0
	zero_momentum.y = 0
	#print(self)
	#print(enemy_detection_area2d)
	player_pos = Player.get_global_position()
	enemy_pos = get_global_position()
	add_to_group("Enemy")


func _physics_process(delta: float) -> void:
	
	move()
	enemy_hurt()
	enemy_get_parried_dashed()
	enemy_death()
	enemy_grabbed()
	enemy_grabbed_hurt()
	enemy_thrown()
	knockback_direction()
	move_and_slide()
	canvaslayer.set_global_position(self.get_global_position()+Vector2(0, -50))


func move():
	
	if (detection == false) && (attack_state == false) && (retreat_state == false) && (hurt_state == false) && (parried_state == false) && (grabbed_state == false) && (thrown_state == false) && (knockback_by_thrown_state == false):
		enemy_position = get_global_position()
		look_at(Global_variables_functions.player_position)
		direction = Global_variables_functions.player_position - enemy_position
		velocity = direction * speed
		animation.play("Move")


func enemy_hurt():
	
	if (Player.attack_connection == true) && (Player.enemy_body_ID == self) && (grabbed_state == false):
		#print("ENEMY HURT")
		Player.attack_connection = false
		hurt_state = true
		attack_state = false
		detection = false
		parried_state = false
		enemy_detection_area2d.monitoring = false
		animation.stop()
		print("ENEMY_HURT")
		animation.play("GettingHurt")
		enemy_timer_attack.stop()
		enemy_timer_hit.stop()
		enemy_timer_get_parried.stop()
		velocity = Vector2(0, 0)
		enemy_timer_get_hurt.start(0.5)
		
		take_damage()


func enemy_grabbed_hurt():
	
	if (Player.attack_connection == true) && (Player.enemy_body_ID == self) && (grabbed_state == true):
		#print("ENEMY HURT")
		Player.attack_connection = false
		hurt_state = true
		attack_state = false
		detection = false
		parried_state = false
		enemy_detection_area2d.monitoring = false
		print("ENEMY_HURT")
		animation.stop()
		animation.play("GettingHurt")
		enemy_timer_attack.stop()
		enemy_timer_hit.stop()
		enemy_timer_get_parried.stop()
		enemy_timer_get_hurt.start(0.5)
		
		take_damage()


func take_damage():
	
	progress_bar.visible = true
	HitPoints = HitPoints - Player.damage
	progress_bar.value = HitPoints
	enemy_timer_visible_HP.start(2)


func enemy_death():
	
	if (HitPoints <= 0):
		death = true
		canvaslayer.queue_free()
		queue_free()


func enemy_get_parried():
	
	#print("Player:", Player.enemy_area_ID, " Enemy: ", enemy_detection_area2d)
	
	if ((Player.block_state == true) && (hurt_state == false)) && (area_detection == true):
		print("PARRIED")
		Player.successfull_parry = false
		parried_state = true
		attack_state = false
		detection = false
		enemy_detection_area2d.monitoring = false
		animation.play("Parried") 
		enemy_timer_attack.stop()
		enemy_timer_hit.stop()
		enemy_timer_get_hurt.stop()
		enemy_timer_get_parried.start(3)


func enemy_get_parried_dashed():
	
	#print(self, Player.aux_enemy_raycast_collided)
	if (Player.dash_over_stun == true) && (self == Player.aux_enemy_raycast_collided):
		Player.aux_enemy_raycast_collided = null
		self.area_hit_areanw.monitoring = false
		self.area_hit_areane.monitoring = false
		self.area_hit_arease.monitoring = false
		self.area_hit_areasw.monitoring = false
		
		print("PARRIED")
		Player.dash_over_stun = false
		Player.successfull_parry = false
		parried_state = true
		attack_state = false
		detection = false
		enemy_detection_area2d.monitoring = false
		animation.play("Parried") 
		enemy_timer_attack.stop()
		enemy_timer_hit.stop()
		enemy_timer_get_hurt.stop()
		enemy_timer_get_parried.start(3)
		ETAMR.start(0.2)


func enemy_grabbed():
	
	if ((Player.grab_state == true) || (Player.pull_state == true) || (Player.clinch_state == true)) && (Player.enemy_raycast_collided == self) && (thrown_state == false)  && (knockback_by_thrown_state == false):
		grabbed_state = true
		attack_state = false
		
		if (enemy_grabbed_canceled_actions == false):
			enemy_grabbed_canceled_actions = true
			animation.stop()
			
		enemy_timer_attack.stop()
		enemy_timer_hit.stop()
		look_at(Global_variables_functions.player_position)
		set_global_position(Player.marker_hand.global_position)
	else:
		grabbed_state = false


func enemy_thrown():
	
	if (Player.throw_state == true) && (Player.enemy_raycast_collided == self) && (thrown_state == false)  && (knockback_by_thrown_state == false):
		thrown_state = true
		grabbed_state = false
		corect_retreat_direction()
		area_hit_other_enemies.monitorable = true
		enemy_timer_thrown.start(0.3)
		print("Thrown")
		
	if (thrown_state == true):
		set_global_position(path_thrown_backward.global_position)


func knockback_direction():
	
	if (knockback_by_thrown_state == true):
		if(area_direction == "nw"):
			set_global_position(knockbackpathse.global_position)
			#print("NW")
		if(area_direction == "ne"):
			set_global_position(knockbackpathsw.global_position)
			#print("NE")
		if(area_direction == "se"):
			set_global_position(knockbackpathnw.global_position)
			#print("SE")
		if(area_direction == "sw"):
			set_global_position(knockbackpathne.global_position)
			#print("SW")


func attack_seq():
	
	if (hurt_state == false) && (parried_state == false) && (grabbed_state == false) && (thrown_state == false):
		velocity = zero_momentum
		attack_state = true
		animation.play("Attack")
		enemy_timer_attack.start(1)
		enemy_timer_hit.start(0.6)
		
		if (area_detection == true):
			attack_area_collided = true


func corect_retreat_direction():
	
	player_pos = Player.get_global_position()
	enemy_pos = get_global_position()
	
	if(player_pos.x < enemy_pos.x) && (player_pos.y < enemy_pos.y):
		retreat_pos = Vector2(1,1)
	
	if(player_pos.x > enemy_pos.x) && (player_pos.y > enemy_pos.y):
		retreat_pos = Vector2(-1,-1)
	
	if(player_pos.x < enemy_pos.x) && (player_pos.y > enemy_pos.y):
		retreat_pos = Vector2(1, -1)
	
	if(player_pos.x > enemy_pos.x) && (player_pos.y < enemy_pos.y):
		retreat_pos = Vector2(-1, 1)


######################################################


func _on_area_2d_body_entered(body: Node2D) -> void:
	
	if (body.name == Player.name) && (grabbed_state == false) && (thrown_state == false):
		attack_seq()
		detection = true


func _on_area_2d_body_exited(body: Node2D) -> void:
	
	if (body.name == Player.name):
		detection = false
		#print ("Body out")


func _on_detection_area_2d_area_entered(area: Area2D) -> void:
	
	if (area.name == Player_array[1].name):
		#print("AREA2D detected by ENEMY")
		area_detection = true


func _on_detection_area_2d_area_exited(area: Area2D) -> void:
	
	if (area.name == Player_array[1].name):
		area_detection = false


##############################-----KNOCK BACK ZONES-----###########################################

func _on_area_nw_area_entered(area: Area2D) -> void:
	
	if ((area != Player.AKBS) && (area != self.area_hit_other_enemies)) || ((area == Player.AKBS) && (parried_state == true)):
		area_hit_areane.monitoring = false
		#area_hit_areanw.monitoring = false
		area_hit_arease.monitoring = false
		area_hit_areasw.monitoring = false
		knockback_by_thrown_state = true
		enemy_timer_knocked_back.start(0.3)
		area_direction = "nw"
		print(area_hit_other_enemies)

func _on_area_ne_area_entered(area: Area2D) -> void:
	
	if ((area != Player.AKBS) && (area != self.area_hit_other_enemies)) || ((area == Player.AKBS) && (parried_state == true)):
		#area_hit_areane.monitoring = false
		area_hit_areanw.monitoring = false
		area_hit_arease.monitoring = false
		area_hit_areasw.monitoring = false
		knockback_by_thrown_state = true
		enemy_timer_knocked_back.start(0.3)
		area_direction = "ne"
		print(area_hit_other_enemies)

func _on_area_se_area_entered(area: Area2D) -> void:
	
	if ((area != Player.AKBS) && (area != self.area_hit_other_enemies)) || ((area == Player.AKBS) && (parried_state == true)):
		area_hit_areane.monitoring = false
		area_hit_areanw.monitoring = false
		#area_hit_arease.monitoring = false
		area_hit_areasw.monitoring = false
		knockback_by_thrown_state = true
		enemy_timer_knocked_back.start(0.3)
		area_direction = "se"
		print(area_hit_other_enemies)

func _on_area_sw_area_entered(area: Area2D) -> void:
	
	if ((area != Player.AKBS) && (area != self.area_hit_other_enemies)) || ((area == Player.AKBS) && (parried_state == true)):
		area_hit_areane.monitoring = false
		area_hit_areanw.monitoring = false
		area_hit_arease.monitoring = false
		#area_hit_areasw.monitoring = false
		knockback_by_thrown_state = true
		enemy_timer_knocked_back.start(0.3)
		area_direction = "sw"
		print(area_hit_other_enemies)

##############################-----KNOCK BACK ZONES-----###########################################
#########################################################################


func _on_enemy_timer_attack_timeout() -> void:
	
	attack_state = false
	retreat_state = true
	attack_connected = false
	attack_area_collided = false
	
	player_pos = Player.get_global_position()
	enemy_pos = get_global_position()

	corect_retreat_direction()
		
	velocity = enemy_pos - player_pos + retreat_pos
	look_at(player_pos)
	animation.play("Move")
	enemy_timer_retreat.start(0.5)


func _on_enemy_timer_hit_timeout() -> void:
	
	if (Player.block_state == false) && (detection == true):
		Global_variables_functions.enemy_attack_hit = true
		
	enemy_get_parried()


func _on_enemy_timer_retreat_timeout() -> void:
	retreat_state = false
	if (detection == true) && (hurt_state == false):
		attack_seq()


func _on_enemy_timer_get_hurt_timeout() -> void:
	hurt_state = false
	enemy_detection_area2d.monitoring = true


func _on_enemy_timer_get_parried_timeout() -> void:
	parried_state = false
	enemy_detection_area2d.monitoring = true


func _on_enemy_timer_thrown_timeout() -> void:
	
	thrown_state = false
	enemy_grabbed_canceled_actions = false
	area_hit_other_enemies.monitorable = false


func _on_enemy_timer_get_knocked_back_timeout() -> void:
	area_hit_areane.monitoring = true
	area_hit_areanw.monitoring = true
	area_hit_arease.monitoring = true
	area_hit_areasw.monitoring = true
	knockback_by_thrown_state = false


func _on_enemy_timer_visible_hp_timeout() -> void:
	
	progress_bar.visible = false


func _on_enemy_timer_areas_monitorible_recovery_timeout() -> void:
	self.area_hit_areanw.monitoring = true
	self.area_hit_areane.monitoring = true
	self.area_hit_arease.monitoring = true
	self.area_hit_areasw.monitoring = true
