extends Node
class_name PowerCarousel

const SEGMENT_COUNT = 8
const TRANSITION_TIME = 0.25

var power = 1
var time = 0.0
var counter = 0
var enabled = false

signal changed(new_value)

func get_powerf():
	return float(power) / SEGMENT_COUNT

func reset():
	power = 1
	counter = 0
	time = 0.0
	emit_signal("changed", power)

func _process(delta):
	if not enabled:
		return

	time += delta

	if time > TRANSITION_TIME:
		time = 0.0
		power = counter % (SEGMENT_COUNT * 2 - 2) + 1

		if (power - 1) / SEGMENT_COUNT > 0:
			power = SEGMENT_COUNT - (power - SEGMENT_COUNT)

		counter += 1
		emit_signal("changed", power)
