extends Label

signal completed

const TIME_UPDATING_INITIAL = 0.3
const TIME_UPDATING_MIN = 0.03

export var active = true
export var duration = 1.2
export var format = "%d"

var value = 0 setget set_value
var last_value = 0
var part_value = 0
var time = 0.0
var time_updating = 0.0

func set_value(new_value):
	value = new_value
	time_updating = TIME_UPDATING_INITIAL
	time = time_updating

	if value == 0:
		last_value = 0
		text = "0" if format.empty() else format % 0
		return

	part_value = (value - last_value) / duration

func _process(delta):
	if active and last_value != value:
		time += delta
		last_value = min(last_value + part_value * delta, value)

		var done = last_value == value

		if time >= time_updating or done:
			time_updating = max(time_updating / 3, TIME_UPDATING_MIN)

			if not format.empty():
				text = format % int(last_value)
			else:
				text = str(int(last_value))

			time = 0.0

			if done:
				emit_signal("completed")
