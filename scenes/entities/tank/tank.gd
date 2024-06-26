extends CharacterBody2D
class_name Tank

signal collected(collectable)
signal reloaded()
signal reload_progress(progress)

const SPEED = 64.0
const TURN_SPEED = 2
const ROTATE_SPEED = 1

@export var weapon: Weapon
@export var drive_water_audio: AudioStream
@export var default_drive_audio: AudioStream

@onready var body_sprite = $BodySprite
@onready var animation_player = $AnimationPlayer
@onready var collision_shape_2d = $CollisionShape2D
@onready var left_track_particles: GPUParticles2D = $LeftTrackParticles
@onready var right_track_particles: GPUParticles2D = $RightTrackParticles
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

var direction := Vector2.RIGHT
var speed_modifier := 1.0
var particle_gradient: GradientTexture1D = null
var in_water := false:
	set(value):
		if in_water != value:
			if value:
				audio_player.stream = drive_water_audio
			else:
				audio_player.stream = default_drive_audio
		in_water = value
var has_control := true

func _ready():
	weapon.reloaded.connect(func (): reloaded.emit())
	weapon.reload_progress.connect(func(progress): reload_progress.emit(progress))

func _physics_process(delta):
	if !has_control:
		return
	var input_direction := Input.get_vector("turn_left", "turn_right","move_backward", "move_forward")
	if input_direction.x != 0:
		# Rotate direction based on input vector and apply turn speed
		direction = direction.rotated(input_direction.x * (PI / 2) * TURN_SPEED * delta)
		rotation = direction.angle()
	if input_direction.y != 0:
		# Move in forward/backward motion and play animation
		animation_player.play("move")
		in_water = World.get_custom_data_at(position, "is_water")
		particle_gradient = World.get_gradient_at(position)
		speed_modifier = World.get_custom_data_at(position, "speed_modifier")
		var move_speed = SPEED * speed_modifier
		velocity = lerp(velocity, (direction.normalized() * input_direction.y) * move_speed, SPEED * delta)
		if !audio_player.playing:
			audio_player.play()
	else:
		# Bring to a stop
		if audio_player.playing:
			audio_player.stop()
		velocity = Vector2.ZERO
		animation_player.play("idle")
	
	if particle_gradient and velocity:
		left_track_particles.process_material.color_ramp = particle_gradient
		right_track_particles.process_material.color_ramp = particle_gradient
		left_track_particles.emitting = true
		right_track_particles.emitting = true
	else:
		left_track_particles.emitting = false
		right_track_particles.emitting = false
	# Apply our movement velocity
	move_and_slide()
	
	# Apply weapon rotation
	#var weapon_rotate_direction := Input.get_axis("rotate_weapon_left", "rotate_weapon_right")
	#weapon.rotation_degrees += (weapon_rotate_direction * ROTATE_SPEED * delta * PI)
	
	# Apply weapon rotation to mouse position
	var mouse_pos = get_local_mouse_position()
	var new_transform = weapon.transform.looking_at(mouse_pos)
	weapon.transform = weapon.transform.interpolate_with(new_transform, ROTATE_SPEED * delta)

func _input(event):
	if !has_control:
		return
	if event.is_action_pressed("weapon_fire"):
		weapon.fire()

func collect(collectable):
	collected.emit(collectable)
