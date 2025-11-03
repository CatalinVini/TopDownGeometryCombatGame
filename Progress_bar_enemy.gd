extends ProgressBar

@onready var progress_bar = $"."
@onready var Enemy = get_tree().get_first_node_in_group("Enemy")

func _physics_process(delta: float) -> void:
	progress_bar.value = Enemy.HitPoints
