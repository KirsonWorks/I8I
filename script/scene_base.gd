tool
extends Node

class_name SceneBase

enum FadeType {NONE = -1, FADE, HOLE, CURTAIN, CURTAIN_REVERSE}

export (float) var scene_fade_duration = 0.5
export (float) var scene_fade_delay = 0.5
export (FadeType) var scene_start_fade_type = FadeType.NONE
export (FadeType) var scene_finish_fade_type = FadeType.NONE

var tween = null
var paused = false
var leaving_scene = false

func _ready():
	tween = Tween.new()
	add_child(tween)
	
	if scene_start_fade_type != FadeType.NONE:
		$post_effect.fade(scene_start_fade_type, scene_fade_duration, scene_fade_delay, true)
		
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_FOCUS_OUT:
		get_tree().paused = true
	
	if what == MainLoop.NOTIFICATION_WM_FOCUS_IN:
		if not paused:
			get_tree().paused = false

func change_scene(path):
	if Engine.editor_hint:
		return
		
	if has_node("post_effect") and not $post_effect.completed():
		return
	
	leaving_scene = true
	
	if scene_finish_fade_type != FadeType.NONE:
		$post_effect.fade(scene_finish_fade_type, scene_fade_duration, 0.0, false)
		yield($post_effect, "completed")
		
	if path is String:
		assert(not path.empty())
		get_tree().change_scene(path)
	elif path is PackedScene:
		get_tree().change_scene_to(path)
	else:
		get_tree().reload_current_scene()
