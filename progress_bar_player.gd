extends ProgressBar

@onready var progress_bar = $"."
@onready var Player = get_tree().get_first_node_in_group("Player")
@onready var VarietyText = $"../CodeEdit"

func _physics_process(delta: float) -> void:
	progress_bar.value = Player.HitPoints
	VarietyText.text = "Variety \n Level: " + str(Player.variety_for_text)
	
