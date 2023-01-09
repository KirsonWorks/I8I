tool
extends Node

const HI_SCORE_FILENAME = "user://hiscore.181"
const music_res = preload("res://music/music.ogg")

var stage_num = 1
var stages = []
var hiscore = []
var prev_collision_sound_playing = 0
var music_player

func _ready():
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = linear2db(0.2)
	music_player.stream = music_res
	music_player.play()
	add_child(music_player)
	 
	stages = Utils.scan_dir("res://scene/stage/", Utils.ABSOLUTE)

	for stage in stages:
		hiscore.push_back(0)
	
	load_hiscore_from_file()

func music_paused(value):
	music_player.volume_db = linear2db(0.05 if value else 0.2)

func get_current_stage_scene_path():
	return stages[stage_num - 1]

func update_current_hiscore(score, has_cup):
	var score_data = hiscore[stage_num - 1]
	var cur_score = score_data & 0xffff
	var cur_cup = bool(score_data >> 16)

	if cur_score < score:
		cur_score = int(score)
	
	if cur_cup < has_cup:
		cur_cup = has_cup
	
	var new_score_data = cur_score | int(cur_cup) << 16
	
	if new_score_data != score_data:
		hiscore[stage_num - 1] = new_score_data
		save_hiscore_to_file()

func get_current_hiscore():
	return hiscore[stage_num - 1] & 0xffff

func get_current_cup():
	return hiscore[stage_num - 1] >> 16

func save_hiscore_to_file():
	var f = File.new()

	f.open(HI_SCORE_FILENAME, File.WRITE)
	
	for value in hiscore:
		f.store_line(str(value))

	f.close()

func load_hiscore_from_file():
	var f = File.new()

	if f.file_exists(HI_SCORE_FILENAME):
		f.open(HI_SCORE_FILENAME, File.READ)

		var i = 0
		while not f.eof_reached():
			var line = f.get_line()
			
			if line == "":
				break
			
			var value = int(line)
			
			if i < hiscore.size():
				hiscore[i] = value
			else:
				hiscore.push_back(value)

			i += 1

func next_stage():
	var end = (stage_num + 1) > stages.size()
	
	if not end:
		stage_num += 1
	
	return not end
