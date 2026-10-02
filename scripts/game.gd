# 게임 전체 상태(골드, 퀘스트 진행, 가방), 소리, 화면 전환, 저장을 맡는다.
extends Node

const SAVE_PATH := "user://save.json"
const WORLD := preload("res://scenes/world.tscn")

var gold := 0
var day := 1           # 지금 며칠째인지
var step := 0          # 그날 이야기 진행 단계 (scripts/dayN.gd 참고)
var flags := {}        # 퀘스트 완료 여부 등
var items: Array[String] = []
var map := "home"
var arrive := ""       # 도착할 문 글자 ("" = P 위치)
var best_day := 0      # 저장: 끝낸 날 중 가장 큰 값

var _bgm := AudioStreamPlayer.new()
var _bgm_name := ""
var _sfx: Array[AudioStreamPlayer] = []
var _whisper := Timer.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	add_child(_bgm)
	_bgm.finished.connect(_bgm.play)  # 반복 재생
	for i in 4:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx.append(p)
	add_child(_whisper)
	_whisper.one_shot = true
	_whisper.timeout.connect(_on_whisper)
	load_save()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("fullscreen"):
		var fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fs else DisplayServer.WINDOW_MODE_FULLSCREEN)


# 키보드 + 게임패드(스팀덱) 조작
func _setup_input() -> void:
	# 동작: [[키보드 키들], [패드 버튼들]]
	var binds := {
		"up": [[KEY_UP, KEY_W], [JOY_BUTTON_DPAD_UP]],
		"down": [[KEY_DOWN, KEY_S], [JOY_BUTTON_DPAD_DOWN]],
		"left": [[KEY_LEFT, KEY_A], [JOY_BUTTON_DPAD_LEFT]],
		"right": [[KEY_RIGHT, KEY_D], [JOY_BUTTON_DPAD_RIGHT]],
		"accept": [[KEY_Z, KEY_SPACE, KEY_ENTER], [JOY_BUTTON_A]],
		"cancel": [[KEY_X, KEY_ESCAPE], [JOY_BUTTON_B]],
		"map": [[KEY_M], [JOY_BUTTON_Y]],
		"run": [[KEY_SHIFT], [JOY_BUTTON_X]],
		"fullscreen": [[KEY_F11], []],
	}
	var axes := {"up": [JOY_AXIS_LEFT_Y, -1.0], "down": [JOY_AXIS_LEFT_Y, 1.0],
		"left": [JOY_AXIS_LEFT_X, -1.0], "right": [JOY_AXIS_LEFT_X, 1.0]}
	for action in binds:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.4)
		for code in binds[action][0]:
			var k := InputEventKey.new()
			k.physical_keycode = code
			InputMap.action_add_event(action, k)
		for code in binds[action][1]:
			var b := InputEventJoypadButton.new()
			b.button_index = code
			InputMap.action_add_event(action, b)
		if action in axes:
			var m := InputEventJoypadMotion.new()
			m.axis = axes[action][0]
			m.axis_value = axes[action][1]
			InputMap.action_add_event(action, m)


# ---------- 소리 ----------
# assets/audio 에 같은 이름의 .ogg 가 있으면 그걸, 없으면 .wav 를 쓴다.
func _stream(name: String) -> AudioStream:
	for ext in [".ogg", ".mp3", ".wav"]:
		var path: String = "res://assets/audio/" + name + ext
		if ResourceLoader.exists(path):
			return load(path)
	return null


func play_bgm(name: String, pitch := 1.0) -> void:
	_bgm.pitch_scale = pitch
	if name == _bgm_name:
		return
	_bgm_name = name
	_bgm.stream = _stream(name)
	_bgm.volume_db = -6.0
	if _bgm.stream:
		_bgm.play()


func stop_bgm() -> void:
	_bgm_name = ""
	_bgm.stop()


func sfx(name: String, volume_db := 0.0) -> void:
	for p in _sfx:
		if not p.playing:
			p.stream = _stream(name)
			p.volume_db = volume_db
			p.play()
			return


# ---------- 환청 (가끔 들리는 이상한 소리) ----------
func whispers(on: bool) -> void:
	if on and _whisper.is_stopped():
		_whisper.start(randf_range(25.0, 55.0))
	elif not on:
		_whisper.stop()


func whisper_now(text := "") -> void:
	sfx("sfx_whisper", -10.0)
	UI.glitch(text if text else ["...들려?", "여기야", "ㄴr가", "...", "왜 왔어"].pick_random())


func _on_whisper() -> void:
	if not UI.busy:
		whisper_now()
	whispers(true)


# ---------- 화면 전환 ----------
func go(to_map: String, door := "") -> void:
	map = to_map
	arrive = door
	await UI.fade(true)
	get_tree().change_scene_to_packed(WORLD)
	await get_tree().process_frame
	UI.fade(false)


func new_game() -> void:
	gold = 0
	items = []
	start_day(1)
	go("home")


func start_day(n: int) -> void:
	day = n
	step = 0
	flags = {}


func continue_game() -> void:
	load_save()
	start_day(day)
	go("home")


# ---------- 저장 ----------
func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"best_day": best_day, "day": day, "gold": gold, "items": items}))


func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if data is Dictionary:
		best_day = int(data.get("best_day", 0))
		day = clampi(int(data.get("day", 1)), 1, best_day + 1)
		gold = int(data.get("gold", 0))
		items.assign(data.get("items", []))
