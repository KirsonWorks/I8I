tool
class_name Ball
extends RigidBody2D

const snd_ball_hit = preload("res://sound/ball-hit.wav")

enum State {NONE, NORMAL, MOVE_TO_TARGET, DIE}

const POWER_MIN = 5.0
const POWER_RANGE = 20.0

export (bool) var is_cue_ball setget set_cue_ball

var state = State.NONE
var target = Vector2.ZERO

func set_cue_ball(value):
	set_sprite_index(int(value))
	is_cue_ball = value

func set_sprite_index(index):
	var rr = $texture.region_rect
	$texture.region_rect = Rect2(index * rr.size.x, 0, rr.size.x, rr.size.y)

func is_stopped():
	return linear_velocity.length() == 0 and state != State.MOVE_TO_TARGET

func klapstos(tgt, power):
	var diff = tgt - position
	var angle = atan2(diff.y, diff.x)
	var direction = Vector2(cos(angle), sin(angle))
	apply_impulse(Vector2.ZERO, direction * (POWER_MIN + POWER_RANGE * power))
	$sound.stream = snd_ball_hit
	$sound.pitch_scale = 0.55 + 0.45 * power
	$sound.play()
	
func in_the_hole(tgt):
	self.target = tgt
	call_deferred("change_state", State.MOVE_TO_TARGET) 

func change_state(new_state):
	if state == new_state:
		return

	match new_state:
		State.NORMAL:
			pass

		State.MOVE_TO_TARGET:
			applied_torque = 0
			applied_force = Vector2.ZERO
			linear_velocity = Vector2.ZERO
			$collider.disabled = true
			$anim.play("cue_ball_holed" if is_cue_ball else "ball_holed")
		
		State.DIE:
			queue_free()
	
	state = new_state

func _ready():
	change_state(State.NORMAL)

func _integrate_forces(phystate):
	rotation_degrees = 0
	
	match state:
		State.NORMAL:
			linear_velocity *= 0.995
			
			if linear_velocity.length() < 5.0:
				linear_velocity = Vector2.ZERO
			
			var time = OS.get_ticks_msec()
			
			if time - Global.prev_collision_sound_playing > 100 and phystate.get_contact_count() > 0 and phystate.linear_velocity.length() > 0:
				Global.prev_collision_sound_playing = time
				var obj = phystate.get_contact_collider_object(0)
				
				if obj is RigidBody2D:
					$sound.pitch_scale = 1
					$sound.stream = snd_ball_hit
					$sound.play()

		State.MOVE_TO_TARGET:
			if target:
				var pos = phystate.transform.origin
				phystate.transform.origin = pos.linear_interpolate(target, phystate.step * 3.0)
