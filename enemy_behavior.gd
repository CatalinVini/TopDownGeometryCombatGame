extends Node3D

var timer_enemy_behavior: Timer
var player_position_3D: Vector3
var attack_connected = false
var enemy_array = []


func _ready() -> void:
	create_timer()


func _physics_process(delta: float) -> void:
	pass


func create_timer():
	timer_enemy_behavior = Timer.new()
	timer_enemy_behavior.one_shot = true
	add_child(timer_enemy_behavior)
	timer_enemy_behavior.timeout.connect(_on_enemy_behavior_timer_timeout)


func _on_enemy_behavior_timer_timeout():
	print("HEY")
