class_name Stage
extends StaticBody2D

export (int, 1, 10) var live_limit = 3

enum State { NONE, MOVE_WAITING, MOVE_STARTED, MOVE_COMPLETED }

const ball_scene = preload("res://scene/actor/ball.tscn")

signal move_waiting
signal move_started
signal move_completed
signal stage_won
signal stage_lost
signal many_goals_one_move
signal score_changed(new_score)
signal lives_changed(new_lives)

var cue_ball = null
var cue_ball_last_position
var cue_ball_loss_count = 0
var state = State.NONE
var goals_in_row = 0
var last_power = 0
var ball_count = 0
var lives = 0
var score = 0
var goals_one_move_time = 0
var goals_one_move = 0
var many_goals_fired = false

func add_lives(count):
	var old_lives = lives
	lives = clamp(lives + count, 0, live_limit)

	if lives - old_lives < 0:
		$snd_loss_ball.play()

	emit_signal("lives_changed", lives)

func add_score(value):
	score += value
	emit_signal("score_changed", score)

func is_move_waiting():
	return state == State.MOVE_WAITING

func change_state(new_state):
	if state == new_state:
		return

	state = new_state

	match new_state:
		State.MOVE_WAITING:
			if not cue_ball:
				cue_ball = create_ball(cue_ball_last_position, true)

			emit_signal("move_waiting")

		State.MOVE_STARTED:
			goals_one_move = 0
			goals_one_move_time = 0
			many_goals_fired = false
			emit_signal("move_started")

		State.MOVE_COMPLETED:
			emit_signal("move_completed")
			emit_signal("score_changed", score)

			if ball_count == 0:
				emit_signal("stage_won")
			elif lives == 0:
				emit_signal("stage_lost")
			else:
				change_state(State.MOVE_WAITING)

func _ready():
	add_score(0)
	add_lives(live_limit)
	
	for ball in $balls.get_children():
		if ball.is_cue_ball:
			cue_ball = ball
			cue_ball_last_position = ball.position
			break

	ball_count = $balls.get_child_count() - int(cue_ball != null)
	change_state(State.MOVE_WAITING)

func _physics_process(delta):
	if state == State.MOVE_STARTED:
		var all_stopped = true
		var has_cue_ball = false
		
		for ball in $balls.get_children():
			if not ball.is_stopped():
				all_stopped = false

			if ball.is_cue_ball:
				has_cue_ball = true
		
		if not has_cue_ball:
			cue_ball = false
		
		var ball_count_now = $balls.get_child_count() - int(has_cue_ball)
		var goals = ball_count - ball_count_now
		 
		if goals >= 3:
			if goals > goals_one_move:
				goals_one_move = goals
				goals_one_move_time = 0
				many_goals_fired = false

			goals_one_move_time += delta

			if goals_one_move_time > 0.1 and not many_goals_fired:
				goals_one_move_time = 0
				many_goals_fired = true
				emit_signal("many_goals_one_move")

		if all_stopped:
			var live = -1
			
			if goals > 0:
				live = goals
				goals_in_row += 1
			else:
				goals_in_row = 0

			if not has_cue_ball:
				live -= 1
				goals_in_row = 0
				cue_ball_loss_count += 1

			var points_divider = 1 + int(not has_cue_ball)
			var points = 1000 / points_divider
			var points_ex = 500 * max(0, goals_in_row - 1) / points_divider
			var score_now = 0
			
			for n in goals:
				score_now += last_power * (points + points_ex) * (n + 1)
			
			ball_count -= goals
			add_score(score_now)
			add_lives(clamp(live, -1, live_limit - 1))
			change_state(State.MOVE_COMPLETED)

func klapstos(target, power):
	if state == State.MOVE_WAITING and cue_ball != null:
		last_power = power
		cue_ball_last_position = cue_ball.position
		cue_ball.klapstos(target, power)
		change_state(State.MOVE_STARTED)

func create_ball(position, is_cue_ball):
	var result = ball_scene.instance()
	result.is_cue_ball = is_cue_ball
	result.position = position
	$balls.add_child(result)
	return result
