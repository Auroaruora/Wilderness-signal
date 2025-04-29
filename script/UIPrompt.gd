extends CanvasLayer

@onready var prompt_label: Label = $PromptLabel
func show_message(message: String, duration: float = 2.0):
	prompt_label.text = message
	prompt_label.show()
	await get_tree().create_timer(duration).timeout
	prompt_label.hide()

func hide_message():
	prompt_label.hide()
