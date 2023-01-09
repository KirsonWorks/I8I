extends SceneBase

func _ready():
	Global.music_paused(false)

	for i in Global.stages.size():
		$ui/screen/menu/slot_stage.data.append(str(i + 1))

	$ui/screen/menu/slot_stage.data_index = Global.stage_num - 1

func _on_ui_item_play_action():
	Global.stage_num = $ui/screen/menu/slot_stage.data_index + 1
	change_scene("res://scene/game.tscn")
