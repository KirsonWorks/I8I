extends "res://script/scene_base.gd"

enum StageResult { UNKNOWN, WON, LOST }

const img_ball_a = preload("res://texture/ball-a.png")
const img_ball_b = preload("res://texture/ball-b.png")
const img_arrow_a = preload("res://texture/arrow-a.png")
const img_arrow_b = preload("res://texture/arrow-b.png")
const img_cup_a = preload("res://texture/cup.png")
const img_cup_b = preload("res://texture/cup-d.png")

onready var indicators = $ui/screen/hstack_header/hstack_panel/img_panel_center/container/indicators
onready var label_score = $ui/screen/hstack_header/img_header/label_score
onready var label_hiscore = $ui/screen/hstack_header/img_header/label_hiscore
onready var label_hiscore_anim = $ui/screen/hstack_header/img_header/label_hiscore/anim
onready var image_cup_anim = $ui/screen/hstack_header/img_header/img_cup/anim

var stage
var stage_result

func next_stage():
	if Global.next_stage():
		change_scene(null)
	else:
		go_to_menu()

func retry_stage():
	change_scene(null)

func go_to_menu():
	change_scene("res://scene/menu.tscn")
	
func _ready():
	Global.music_paused(false)
	var stage_scene = load(Global.get_current_stage_scene_path())
	stage = stage_scene.instance()
	stage.connect("move_waiting", self, "_on_stage_move_waiting")
	stage.connect("move_started", self, "_on_stage_move_started")
	stage.connect("move_completed", self, "_on_stage_move_completed")
	stage.connect("lives_changed", self, "_on_stage_lives_changed")
	stage.connect("score_changed", self, "_on_stage_score_changed")
	stage.connect("stage_won", self, "_on_stage_won")
	stage.connect("stage_lost", self, "_on_stage_lost")
	stage.connect("many_goals_one_move", self, "_on_stage_many_goals_one_move")
	$stage_holder.add_child(stage)
	label_hiscore.value = Global.get_current_hiscore()
	$ui/screen/hstack_header/img_header/img_cup.texture = img_cup_a if Global.get_current_cup() else img_cup_b

func _process(_delta):
	if stage.is_move_waiting():
		$aim.points[0] = stage.cue_ball.position
		$aim.points[1] = get_viewport().get_mouse_position()
	
func _input(event):
	if event.is_action_released("klapstos"):
		stage.klapstos(event.position, $power_carousel.get_powerf())

	if stage_result != StageResult.UNKNOWN  and event.is_action_released("ui_accept"):
		match stage_result:
			StageResult.WON:
				next_stage()
			
			StageResult.LOST:
				retry_stage()

	if event.is_action_released("ui_cancel"):
		go_to_menu()

func _on_stage_move_waiting():
	$power_carousel.enabled = true
	$aim.visible = true
	
func _on_stage_move_started():
	$power_carousel.enabled = false
	$aim.visible = false

func _on_stage_move_completed():
	pass

func _on_power_carousel_changed(new_value):
	if not indicators:
		return

	for i in range(3, 11):
		var indicator = indicators.get_child(i)
		var index = i - 3
		indicator.texture = img_arrow_b if index <= new_value - 1 else img_arrow_a

func _on_stage_lives_changed(new_lives):
	if not indicators:
		return

	for i in 3:
		var indicator = indicators.get_child(i)
		indicator.texture = img_ball_b if (2 - i) >= new_lives else img_ball_a

func _on_stage_score_changed(new_score):
	if label_score:
		label_score.value = new_score

func update_hiscore():
	if stage.score > Global.get_current_hiscore():
		var won_cup = stage.cue_ball_loss_count == 0 and not Global.get_current_cup()
		Global.update_current_hiscore(stage.score, won_cup)
		label_hiscore.value = stage.score
		yield(label_hiscore, "completed")
		label_hiscore_anim.play("blink")
		yield(label_hiscore_anim, "animation_finished")
		
		if won_cup:
			image_cup_anim.play("won")
			yield(image_cup_anim, "animation_finished")

func _on_stage_won():
	yield(get_tree().create_timer(0.5), "timeout")
	Global.music_paused(true)
	$ui/cutscene/anim.play("winner")
	yield(label_score, "completed")
	update_hiscore()
	stage_result = StageResult.WON

func _on_stage_lost():
	yield(get_tree().create_timer(0.5), "timeout")
	Global.music_paused(true)
	$ui/cutscene/anim.play("loser")
	stage_result = StageResult.LOST

func _on_stage_many_goals_one_move():
	$ui/surprised/anim.play("show")
	yield($ui/surprised/anim, "animation_finished")
