extends Area2D

func _on_body_shape_entered(_body_rid, body, _body_shape_index, _local_shape_index):
	if body.has_method("in_the_hole"):
		body.in_the_hole(position)
		$sound.play()
