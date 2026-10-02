# 2일차 이야기: 운동장 3바퀴 -> "무언가" -> 400 골드 -> 사탕 사 먹기 -> 졸음 -> 잠.
# Game.step: 0 퀘스트 받기 / 1 운동장 돌기 / 2 보상 받기 / 3 사탕 사 먹기 / 4 집에 가서 자기
extends RefCounted

const GUIDE := "???"
const SHOP := "ISTRUE"
const NIGHT_WHISPER := "봤지?"
const LAPS := 3


static func objectives() -> Array:
	match Game.step:
		0: return [["???에게 퀘스트 받기", false]]
		1: return [["운동장 %d바퀴 돌기  (%d/%d)" % [LAPS, Game.flags.get("laps", 0), LAPS], false]]
		2: return [["???에게 돌아가기", false]]
		3: return [["tHE shop에서 사탕 사 먹기", false]]
		_: return [["집에 가서 자기", false]]


static func marker_char() -> String:
	match Game.step:
		1: return "" if Game.map == "field" else "G"
		2: return "G" if Game.map == "field" else "H"
		3: return "S"
		4: return "H"
	return ""


static func whispers_on() -> bool: return Game.step >= 1 and Game.step <= 3
static func map_ready() -> bool: return true
static func can_sleep() -> bool: return Game.step == 4


static func on_enter(world) -> void:
	if Game.map == "home" and Game.step == 0 and not Game.flags.get("hello"):
		Game.flags.hello = true
		await world.get_tree().create_timer(0.6).timeout
		await UI.say(GUIDE, ["좋은 아침!", "2일차에 온 걸 환영해.", "오늘 퀘스트도 쉬워. 이리 와 봐!"])
	elif Game.map == "field" and not Game.flags.get("field_seen"):
		Game.flags.field_seen = true
		await world.get_tree().create_timer(0.5).timeout
		await UI.say("", ["운동장이다.", "...대충 만든 것 같지만, 꽤 크다."])
		if Game.step == 1:
			UI.toast("트랙을 따라 %d바퀴!  (Shift: 달리기)" % LAPS)


static func door(ch: String) -> bool:
	if Game.map == "home" and ch == "D" and Game.step == 0:
		await UI.say(GUIDE, ["어디 가? 오늘 퀘스트부터 받아 가!"])
		return false
	return true


# 한 칸 걸을 때마다: 트랙 위에서 운동장 가운데를 몇 바퀴 돌았는지 각도로 센다.
# (트랙을 벗어나 가로지르면 그만큼은 안 쳐 준다)
static func on_step(world) -> void:
	if Game.map != "field" or Game.step != 1:
		return
	var f := Game.flags
	if world.rows[world.cell.y][world.cell.x] != "=":
		f.erase("lap_angle")
		return
	var a := (Vector2(world.cell) - (Vector2(world.size_cells) - Vector2.ONE) / 2).angle()
	if f.has("lap_angle"):
		f.lap_total = f.get("lap_total", 0.0) + wrapf(a - f.lap_angle, -PI, PI)
	f.lap_angle = a
	var laps := int(absf(f.get("lap_total", 0.0)) / TAU)
	if laps <= f.get("laps", 0):
		return
	f.laps = laps
	UI.refresh()
	if laps < LAPS:
		Game.sfx("sfx_quest")
		UI.toast("%d바퀴!" % laps)
	else:
		await _something(world)


# 3바퀴째: "무언가"가 달려왔다가 사라진다
static func _something(world) -> void:
	var tree: SceneTree = world.get_tree()
	Game.whispers(false)
	Game.stop_bgm()
	await tree.create_timer(0.7).timeout
	var s := Sprite2D.new()
	s.texture = preload("res://assets/sprites/something.png")
	s.hframes = 2
	s.centered = false
	s.offset = Vector2(0, -16)
	var center := Vector2(world.size_cells) * 8.0
	s.position = world.player.position + (center - world.player.position).normalized() * 170.0
	world.add_child(s)
	Game.sfx("sfx_rush")
	var tw: Tween = world.create_tween()
	tw.tween_property(s, "position", world.player.position, 0.55).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_method(func(t: float): s.frame = int(t * 12) % 2, 0.0, 1.0, 0.55)
	await tw.finished
	await UI.fade(true, 0.03)
	s.queue_free()
	world.shake()
	await tree.create_timer(0.45).timeout
	await UI.fade(false, 0.15)
	await tree.create_timer(0.6).timeout
	await UI.say("", ["...!!", "방금... 뭐였지?"])
	await tree.create_timer(0.8).timeout
	await UI.say("", ["...아무것도 없다.", "또 이상한 버그인가?"])
	Game.step = 2
	Game.sfx("sfx_quest")
	UI.toast("퀘스트 완료!  운동장 %d바퀴" % LAPS)
	UI.refresh()
	world.refresh()
	Game.play_bgm(world.data.bgm, 0.92)
	Game.whispers(true)


static func interact(id: String, world) -> bool:
	match id:
		"guide": await _guide(world)
		"istrue":
			if Game.step != 3:
				return false
			await _istrue(world)
		_: return false
	return true


static func _guide(world) -> void:
	match Game.step:
		0:
			await UI.say(GUIDE, ["오늘의 퀘스트는...", "운동장 %d바퀴 산책하기!" % LAPS, "운동장은 마을 아래쪽 길 끝에 있어."])
			if await UI.choose("", "운동장에 다녀와도 될까?", ["다녀올게!", "...조금 이따가"]) != 0:
				await UI.say(GUIDE, ["천천히 해. 기다릴게."])
				return
			await UI.say(GUIDE, ["물론이지! 다녀와."])
			Game.step = 1
			Game.sfx("sfx_quest")
			UI.toast("새 퀘스트!")
			UI.refresh()
			world.refresh()
			Game.whispers(true)
		1: await UI.say(GUIDE, ["운동장 %d바퀴! 트랙을 따라 돌면 돼." % LAPS, "Shift를 누르고 있으면 달릴 수 있어."])
		2:
			await UI.say(GUIDE, ["다녀왔어?", "......", "...무슨 일 있었어?", "......",
				"아무 일 없었구나! 다행이다.", "자, 보상이야. 오늘은 특별히 많이!"])
			Game.gold += 400
			Game.sfx("sfx_coin")
			UI.toast("400 골드를 받았다!")
			await UI.say(GUIDE, ["tHE shop 가서 맛있는 거 사 먹어.", "사탕 좋아하잖아."])
			Game.step = 3
			UI.refresh()
			world.refresh()
		3: await UI.say(GUIDE, ["tHE shop에 가 봐. 사탕 맛있잖아."])
		_: await UI.say(GUIDE, ["졸려 보이네.", "얼른 가서 자."])


static func _istrue(world) -> void:
	await UI.say(SHOP, ["또 왔네.", "어서 와. 어서 와."])
	while true:
		match await UI.choose(SHOP, "뭘 줄까?", ["사탕  10G", "망치  100G", "그만두기"]):
			0:
				Game.gold -= 10
				Game.sfx("sfx_coin")
				UI.refresh()
				await UI.say(SHOP, ["사탕.", "오늘도 사탕이구나."])
				await UI.say("", ["사탕을 먹었다.", "...달다.", "......", "갑자기 졸음이 쏟아진다."])
				Game.flags.drowsy = true
				Game.step = 4
				Game.whispers(false)
				world.set_drowsy()
				UI.refresh()
				world.refresh()
				return
			1: await UI.say(SHOP, ["...", "그건 아직이야.", "돈이 있어도 안 돼.", "아직은."])
			_:
				await UI.say(SHOP, ["또 와."])
				return
