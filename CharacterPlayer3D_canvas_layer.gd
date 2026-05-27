extends CanvasLayer

@onready var CharacterPlayer3D = $"../.."
@onready var Text_edit = $TextEdit

func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	Text_edit.text = "VAR: " + str(CharacterPlayer3D.variety_for_text)
