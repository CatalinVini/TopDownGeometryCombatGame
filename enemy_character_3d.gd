extends CharacterBody3D

@export var speed = 0.5
var offset_dif: Vector2
var enemy_position: Vector3
var direction: Vector2
var zero_momentum: Vector3
var player_pos: Vector3
var enemy_pos: Vector3
var retreat_pos: Vector3
var detection = false
var attack_state = false
var retreat_state = false
var hurt_state = false
var hurt_by_powered = false
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
var x
var y
var determinedZone

@onready var animation = $"../AnimationPlayer"
@onready var enemy_timer_attack = $"../EnemyTimerAttack"
@onready var enemy_timer_hit = $"../EnemyTimerHit"
@onready var enemy_timer_retreat = $"../EnemyTimerRetreat"
@onready var enemy_timer_get_hurt = $"../EnemyTimerGetHurt"
@onready var enemy_timer_knocked_back = $"../EnemyTimerGetKnockedBack"
@onready var enemy_timer_get_parried = $"../EnemyTimerGetParried"
@onready var enemy_timer_thrown = $"../EnemyTimerThrown"
@onready var enemy_timer_visible_HP = $"../EnemyTimerVisibleHP"
@onready var enemy_timer_hurt_powered = $"../EnemyTimerGetHurtPowered"

@onready var enemy_detection_area2d =  $DetectionArea2D
@onready var Player = get_tree().get_first_node_in_group("Player")
@onready var Player_array = get_tree().get_nodes_in_group("Player")
@onready var path_thrown_backward = $KnockBackPathN/KnockBackPatheN
@onready var area_hit_other_enemies = $AreaHitAnotherEnemies
@onready var area_hit_areanw = $AreaNW
@onready var area_hit_areane = $AreaNE
@onready var area_hit_arease = $AreaSE 
@onready var area_hit_areasw = $AreaSW
@onready var knockbackpathse = $KnockBackPathSE/KnockBackPatheSE
@onready var knockbackpaths = $KnockBackPathS/KnockBackPatheS
@onready var knockbackpathsw = $KnockBackPathSW/KnockBackPatheSW
@onready var knockbackpathw = $KnockBackPathW/KnockBackPatheW
@onready var knockbackpathnw = $KnockBackPathNW/KnockBackPatheNW
@onready var knockbackpathn = $KnockBackPathN/KnockBackPatheN
@onready var knockbackpathne = $KnockBackPathNE/KnockBackPatheNE
@onready var knockbackpathe = $KnockBackPathE/KnockBackPatheE
@onready var areaKnockBackZonehSE = $AreaKnockBackZoneSE
@onready var areaKnockBackZonehS = $AreaKnockBackZoneS
@onready var areaKnockBackZonehSW = $AreaKnockBackZoneSW
@onready var areaKnockBackZonehW = $AreaKnockBackZoneW
@onready var areaKnockBackZonehNW = $AreaKnockBackZoneNW
@onready var areaKnockBackZonehN = $AreaKnockBackZoneN
@onready var areaKnockBackZonehNE = $AreaKnockBackZoneNE
@onready var areaKnockBackZonehE = $AreaKnockBackZoneE
@onready var canvaslayer = $"../NodeForCanvas"
@onready var progress_bar = $"../NodeForCanvas/Control/ProgressBar"
@onready var ETAMR = $"../EnemyTimerAreasMonitoribleRecovery"

var areaZone = []


func _ready():
	
	enemy_position.x = 0
	enemy_position.y = 0
	enemy_position.z = 0
	zero_momentum.x = 0
	zero_momentum.y = 0
	zero_momentum.z = 0
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
	#canvaslayer.set_global_position(self.get_global_position()+Vector2(0, -50))
	CZTP()


func move():
	
	if (detection == false) && (attack_state == false) && (retreat_state == false) && (hurt_state == false) && (parried_state == false) && (grabbed_state == false) && (thrown_state == false) && (knockback_by_thrown_state == false):
		enemy_position = get_global_position()
		look_at(Global_variables_functions.player_position_3D)
		
		if (Player.global_position.x < 0):
			x = - 1
		else:
			x = 1
		
		if (Player.global_position.y < 0):
			y = - 1
		else:
			y = 1
		
		direction = Vector2(x, y)
		
		velocity = (Global_variables_functions.player_position_3D - self.global_position) * speed
		
		#velocity = direction * 20
		#print(direction * speed)
		
		animation.play("Move")


func enemy_hurt():
	
	if (Player.attack_connection == true) && (Player.enemy_body_ID == self) && (grabbed_state == false) && (Player.power_attack_connection == false):
		#print("ENEMY HURT")
		Player.attack_connection = false
		hurt_state = true
		attack_state = false
		detection = false
		parried_state = false
		enemy_detection_area2d.monitoring = false
		animation.stop()
		#print("ENEMY_HURT")
		animation.play("GettingHurt")
		enemy_timer_attack.stop()
		enemy_timer_hit.stop()
		enemy_timer_get_parried.stop()
		velocity = Vector3.ZERO
		enemy_timer_get_hurt.start(0.5)

		take_damage()
	elif (Player.attack_connection == true) && (Player.enemy_body_ID == self) && (grabbed_state == false) && (Player.power_attack_connection == true):
		Player.attack_connection = false
		Player.power_attack_connection = false
		hurt_state = true
		hurt_by_powered = true
		attack_state = false
		detection = false
		parried_state = false
		enemy_detection_area2d.monitoring = false
		animation.stop()
		#print("ENEMY_HURT")
		animation.play("GettingHurt")
		enemy_timer_attack.stop()
		enemy_timer_hit.stop()
		enemy_timer_get_parried.stop()
		#velocity = Vector2(0, 0)
		enemy_timer_get_hurt.start(0.5)
		enemy_timer_hurt_powered.start(0.1)
		determinedZone = closestZoneToPlayer()
		
		take_damage()
		
	knockback_direction_power_attacked(determinedZone)
		

func enemy_grabbed_hurt():
	
	if (Player.attack_connection == true) && (Player.enemy_body_ID == self) && (grabbed_state == true):
		#print("ENEMY HURT")
		Player.attack_connection = false
		hurt_state = true
		attack_state = false
		detection = false
		parried_state = false
		enemy_detection_area2d.monitoring = false
		#print("ENEMY_HURT")
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
		#print("PARRIED")
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
		
		#print("PARRIED")
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
	
	if ((Player.grab_state == true) || (Player.pull_state == true) || (Player.clinch_state == true)) && (Player.enemy_raycast_collided == self) && (thrown_state == false) && (knockback_by_thrown_state == false):
		grabbed_state = true
		attack_state = false
		Player.ALOCT_mode_switch = false
		if (enemy_grabbed_canceled_actions == false):
			enemy_grabbed_canceled_actions = true
			animation.stop()
			
		enemy_timer_attack.stop()
		enemy_timer_hit.stop()
		look_at(Global_variables_functions.player_position_3D)
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
		#print("Thrown")
		
	if (thrown_state == true):
		path_thrown_backward.progress = 50
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


func knockback_direction_power_attacked(determinedZone):
	if (hurt_state == true) && (hurt_by_powered == true):
		if(determinedZone.name.right(2) == "SE"):
			print("nw")
			set_global_position(knockbackpathnw.global_position)
		if(determinedZone.name.right(2) == "eS"):
			print("NNNNN")
			set_global_position(knockbackpathn.global_position)
		if(determinedZone.name.right(2) == "SW"):
			print("ne")
			set_global_position(knockbackpathne.global_position)
		if(determinedZone.name.right(2) == "eW"):
			print("e")
			set_global_position(knockbackpathe.global_position)
		if(determinedZone.name.right(2) == "NW"):
			print("se")
			set_global_position(knockbackpathse.global_position)
		if(determinedZone.name.right(2) == "eN"):
			print("s")
			set_global_position(knockbackpaths.global_position)
		if(determinedZone.name.right(2) == "NE"):
			print("sw")
			set_global_position(knockbackpathsw.global_position)
		if(determinedZone.name.right(2) == "eE"):
			print("w")
			set_global_position(knockbackpathw.global_position)


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
		retreat_pos = Vector3(1, 0, 1)
	
	if(player_pos.x > enemy_pos.x) && (player_pos.y > enemy_pos.y):
		retreat_pos = Vector3(-1, 0,-1)
	
	if(player_pos.x < enemy_pos.x) && (player_pos.y > enemy_pos.y):
		retreat_pos = Vector3(1, 0, -1)
	
	if(player_pos.x > enemy_pos.x) && (player_pos.y < enemy_pos.y):
		retreat_pos = Vector3(-1, 0, 1)


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
		#print(area_hit_other_enemies)

func _on_area_ne_area_entered(area: Area2D) -> void:
	
	if ((area != Player.AKBS) && (area != self.area_hit_other_enemies)) || ((area == Player.AKBS) && (parried_state == true)):
		#area_hit_areane.monitoring = false
		area_hit_areanw.monitoring = false
		area_hit_arease.monitoring = false
		area_hit_areasw.monitoring = false
		knockback_by_thrown_state = true
		enemy_timer_knocked_back.start(0.3)
		area_direction = "ne"
		#print(area_hit_other_enemies)

func _on_area_se_area_entered(area: Area2D) -> void:
	
	if ((area != Player.AKBS) && (area != self.area_hit_other_enemies)) || ((area == Player.AKBS) && (parried_state == true)):
		area_hit_areane.monitoring = false
		area_hit_areanw.monitoring = false
		#area_hit_arease.monitoring = false
		area_hit_areasw.monitoring = false
		knockback_by_thrown_state = true
		enemy_timer_knocked_back.start(0.3)
		area_direction = "se"
		#print(area_hit_other_enemies)

func _on_area_sw_area_entered(area: Area2D) -> void:
	
	if ((area != Player.AKBS) && (area != self.area_hit_other_enemies)) || ((area == Player.AKBS) && (parried_state == true)):
		area_hit_areane.monitoring = false
		area_hit_areanw.monitoring = false
		area_hit_arease.monitoring = false
		#area_hit_areasw.monitoring = false
		knockback_by_thrown_state = true
		enemy_timer_knocked_back.start(0.3)
		area_direction = "sw"
		#print(area_hit_other_enemies)


func _on_area_knock_back_zone_se_area_entered(area: Area2D) -> void:
	areaZone.append(areaKnockBackZonehSE)
	#closestZoneToPlayer()
func _on_area_knock_back_zone_s_area_entered(area: Area2D) -> void:
	areaZone.append(areaKnockBackZonehS)
	#closestZoneToPlayer()
func _on_area_knock_back_zone_sw_area_entered(area: Area2D) -> void:
	areaZone.append(areaKnockBackZonehSW)
	#closestZoneToPlayer()
func _on_area_knock_back_zone_w_area_entered(area: Area2D) -> void:
	areaZone.append(areaKnockBackZonehW)
	#closestZoneToPlayer()
func _on_area_knock_back_zone_nw_area_entered(area: Area2D) -> void:
	areaZone.append(areaKnockBackZonehNW)
	#closestZoneToPlayer()
func _on_area_knock_back_zone_n_area_entered(area: Area2D) -> void:
	areaZone.append(areaKnockBackZonehN)
	#closestZoneToPlayer()
func _on_area_knock_back_zone_ne_area_entered(area: Area2D) -> void:
	areaZone.append(areaKnockBackZonehNE)
	#closestZoneToPlayer()
func _on_area_knock_back_zone_e_area_entered(area: Area2D) -> void:
	areaZone.append(areaKnockBackZonehE)
	#closestZoneToPlayer()

func _on_area_knock_back_zone_se_area_exited(area: Area2D) -> void:
	eraseUseless(areaKnockBackZonehSE)

func _on_area_knock_back_zone_s_area_exited(area: Area2D) -> void:
	eraseUseless(areaKnockBackZonehS)

func _on_area_knock_back_zone_sw_area_exited(area: Area2D) -> void:
	eraseUseless(areaKnockBackZonehSW)

func _on_area_knock_back_zone_w_area_exited(area: Area2D) -> void:
	eraseUseless(areaKnockBackZonehW)

func _on_area_knock_back_zone_nw_area_exited(area: Area2D) -> void:
	eraseUseless(areaKnockBackZonehNW)

func _on_area_knock_back_zone_n_area_exited(area: Area2D) -> void:
	eraseUseless(areaKnockBackZonehN)

func _on_area_knock_back_zone_ne_area_exited(area: Area2D) -> void:
	eraseUseless(areaKnockBackZonehNE)

func _on_area_knock_back_zone_e_area_exited(area: Area2D) -> void:
	eraseUseless(areaKnockBackZonehE)

func closestZoneToPlayer():
	var min = Vector2.ZERO
	var memorizedAreaZone = null
	if !areaZone.is_empty():
		min = areaZone[0].global_position
		memorizedAreaZone = areaZone[0]
		for i in areaZone:
			if (abs(Player.global_position - i.global_position) < min):
				min = abs(Player.global_position - i.global_position)
				memorizedAreaZone = i
				#determined_zone = memorizedAreaZone
				#print("Min Moddified")
	#print(areaZone)
		#print("MIN: ", min)
		#print("memorizedAreaZone: ", memorizedAreaZone)
	else:
		#print("AreaZone EMPTY")
		pass
	return memorizedAreaZone

func eraseUseless(i):
	areaZone.erase(i)
	#print("erase")

func CZTP():
	#if (Input.is_action_just_pressed("attack")):
		#closestZoneToPlayer()
	pass

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
	path_thrown_backward.progress = 20
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


func _on_enemy_timer_get_hurt_powered_timeout() -> void:
	hurt_by_powered = false
