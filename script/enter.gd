extends Entity

signal tunnel_used

func _on_body_entered(body: Node2D):
	if body.name == "Character":
		tunnel_used.emit()
		queue_free.call_deferred()
