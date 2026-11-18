
extends Control

@export var note_speed: float = 280.0
@export var hit_window: float = 50.0
@export var bpm: float = 174.0
@export var first_beat_time: float = 2.0
@export var hit_power: float = 5.0
@export var miss_power: float = 6.0

@onready var music: AudioStreamPlayer = $Music
@onready var falling_notes: Control = $RhythmUI/FallingNotes
@onready var brayan: AnimatedSprite2D = $Stage/Brayan
@onready var teacher: AnimatedSprite2D = $Stage/Teacher
@onready var battle_bar: ProgressBar = $RhythmUI/BattleBar

@onready var receptors: Array[TextureRect] = [
	$RhythmUI/Receptors/LeftArrow,
	$RhythmUI/Receptors/DownArrow,
	$RhythmUI/Receptors/UpArrow,
	$RhythmUI/Receptors/RightArrow
]

const ACTIONS = [
	"rhythm_left",
	"rhythm_down",
	"rhythm_up",
    "rhythm_right"
]

const ANIMATIONS = [
	"left",
	"down",
	"up",
    "right"
]

# Temporary musical pattern.
const NOTE_PATTERN = [0, 1, 2, 3, 2, 1, 0, 3]

var chart: Array[Dictionary] = []
var active_notes: Array[Dictionary] = []
var next_teacher_note_index: int = 0
var next_note_index: int = 0

var song_time: float = 0.0
var battle_value: float = 50.0
var battle_finished: bool = false


func _ready() -> void:
	battle_bar.min_value = 0.0
	battle_bar.max_value = 100.0
	battle_bar.show_percentage = false
	update_battle_bar()

	brayan.animation_finished.connect(
		_on_brayan_animation_finished
	)

	teacher.animation_finished.connect(
		_on_teacher_animation_finished
	)

	brayan.play("starty")
	teacher.play("starty")

	
	music.finished.connect(on_song_finished)

	if music.stream == null:
		push_error("Assign an audio file to the Music node.")
		return

	build_chart()
	music.play()



func build_chart() -> void:
	chart.clear()
	var next_note_index = 0
	next_teacher_note_index = 0

	var path: String = "res://musica/english_chart.json"

	if not FileAccess.file_exists(path):
		push_error("Chart file not found: " + path)
		return

	var json_text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(json_text)

	if not parsed is Dictionary:
		push_error("Invalid chart JSON.")
		return

	var song_data: Dictionary = parsed
	var notes: Array = song_data.get("notes", [])

	for entry in notes:
		if not entry is Dictionary:
			continue

		var note_time: float = float(entry["time"])
		var direction: int = int(entry["direction"])

		if direction < 0 or direction > 3:
			continue

		chart.append({
			"time": note_time,
			"direction": direction
		})

	chart.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return a["time"] < b["time"]
	)

	print("Vocal notes loaded: ", chart.size())


func get_song_time() -> float:
	var time: float = music.get_playback_position()

	time += AudioServer.get_time_since_last_mix()
	time -= AudioServer.get_output_latency()

	return maxf(0.0, time)


func _process(_delta: float) -> void:
	if battle_finished or not music.playing:
		return

	song_time = maxf(song_time, get_song_time())


	# Teacher sings when the note reaches its receptor.
	while next_teacher_note_index < chart.size():
		var teacher_note: Dictionary = chart[next_teacher_note_index]

		var note_time: float = teacher_note["time"]
		var direction: int = teacher_note["direction"]

		if song_time < note_time:
			break

		teacher.stop()
		teacher.play(ANIMATIONS[direction])

		next_teacher_note_index += 1


	# Spawn notes early enough to reach the receptors.
	while next_note_index < chart.size():
		var data: Dictionary = chart[next_note_index]
		var direction: int = data["direction"]
		var hit_time: float = data["time"]

		var receptor: TextureRect = receptors[direction]
		var target: Vector2 = get_target_position(receptor)

		var travel_time: float = (
			target.y + receptor.size.y
		) / note_speed

		if song_time < hit_time - travel_time:
			break

		spawn_note(direction, hit_time)
		next_note_index += 1

	# Keep every note synchronized with the music.
	for data in active_notes:
		var note: TextureRect = data["note"]
		var receptor: TextureRect = data["receptor"]
		var target: Vector2 = get_target_position(receptor)
		var hit_time: float = data["time"]

		note.position = Vector2(
			target.x,
			target.y - (hit_time - song_time) * note_speed
		)

	# Check player input.
	for direction in range(4):
		if Input.is_action_just_pressed(ACTIONS[direction]):
			try_hit(direction)

	# Count missed notes.
	for i in range(active_notes.size() - 1, -1, -1):
		var data: Dictionary = active_notes[i]
		var hit_time: float = data["time"]

		if song_time > hit_time + hit_window / note_speed:
			var note: TextureRect = data["note"]

			active_notes.remove_at(i)
			note.queue_free()
			on_note_miss()

			if battle_finished:
				return


func get_target_position(receptor: TextureRect) -> Vector2:
	return (
		falling_notes.get_global_transform().affine_inverse()
		* receptor.global_position
	)


func spawn_note(direction: int, hit_time: float) -> void:
	var receptor: TextureRect = receptors[direction]

	if receptor.texture == null:
		return

	var note := TextureRect.new()

	note.texture = receptor.texture
	note.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	note.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note.flip_h = receptor.flip_h
	note.flip_v = receptor.flip_v

	falling_notes.add_child(note)

	note.set_anchors_preset(Control.PRESET_TOP_LEFT)
	note.size = receptor.size

	var target: Vector2 = get_target_position(receptor)

	note.position = Vector2(
		target.x,
		target.y - (hit_time - song_time) * note_speed
	)

	active_notes.append({
		"note": note,
		"receptor": receptor,
		"direction": direction,
		"time": hit_time
	})


func try_hit(direction: int) -> void:
	var best_index: int = -1
	var closest_distance: float = hit_window

	for i in range(active_notes.size()):
		var data: Dictionary = active_notes[i]

		if data["direction"] != direction:
			continue

		var hit_time: float = data["time"]

		var distance: float = absf(
			hit_time - song_time
		) * note_speed

		if distance <= closest_distance:
			closest_distance = distance
			best_index = i

	if best_index == -1:
		return

	var hit_data: Dictionary = active_notes[best_index]
	var hit_note: TextureRect = hit_data["note"]

	active_notes.remove_at(best_index)
	hit_note.queue_free()

	brayan.stop()
	brayan.play(ANIMATIONS[direction])

	on_note_hit()


func on_note_hit() -> void:
	if battle_finished:
		return

	battle_value = maxf(5.0, battle_value - hit_power)
	update_battle_bar()

	print("HIT! Advantage: ", 100.0 - battle_value)


func on_note_miss() -> void:
	if battle_finished:
		return

	battle_value = minf(100.0, battle_value + miss_power)
	update_battle_bar()

	print("MISS! Advantage: ", 100.0 - battle_value)

	if battle_value >= 100.0:
		lose_music_level()


func update_battle_bar() -> void:
	battle_bar.value = battle_value


func _on_brayan_animation_finished() -> void:
	if not battle_finished and brayan.animation != "starty":
		brayan.play("starty")


func _on_teacher_animation_finished() -> void:
	if not battle_finished and teacher.animation != "starty":
		teacher.play("starty")


func on_song_finished() -> void:
	if battle_finished:
		return

	if battle_value < 50.0:
		win_music_level()
	else:
		lose_music_level()


func lose_music_level() -> void:
	if battle_finished:
		return

	battle_finished = true
	music.stop()

	get_tree().change_scene_to_file(
        "res://english_defeat.tscn"
	)

func win_music_level() -> void:
	if battle_finished:
		return

	battle_finished = true
	music.stop()

	get_tree().change_scene_to_file(
        "res://english_victory.tscn"
	)

func retry_level() -> void:
	get_tree().reload_current_scene()
