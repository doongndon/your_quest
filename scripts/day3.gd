# 3일차 이야기: 세상이 어둑하다 -> ???의 집에서 물건 3개 찾기 -> 뒤에 서 있는 ??? -> 600 골드
# -> 창고의 지하실 문 ("그" = "무언가") -> 집으로 튕겨남 -> 사탕 -> 졸음 -> 잠.
# Game.step: 0 퀘스트 받기 / 1 ???의 집에서 물건 찾기 / 2 사탕 사 먹기 / 3 집에 가서 자기
extends RefCounted

const GUIDE := "???"
const SHOP := "ISTRUE"
const ME := "나"
const NIGHT_WHISPER := "열어 줘"
const END_TEXT := "[ 3일차 클리어! ]"
const END_GLITCH := true
const TINT := Color(0.8, 0.79, 0.88)  # 하늘도, 그래픽도 조금 어둡다
const WHISPERS := ["ㅇㅕ...ㄹ", "ㄴr...ㄱr", "ㄱ ㅡ ㄱ ㅏ", "ㄷㅡㄹ...ㄹㅕ?", "...ㅇㅑ", "ㅁ ㅜ ㅓ ㅅ", "...ㅈㅜ", "ㅇㅓ...ㄷ"]
const WHISPER_GAP := Vector2(9.0, 20.0)  # 어제보다 훨씬 자주
# 찾을 물건: [id, 이름, 찾았을 때 혼잣말]
const ITEMS := [
	["candle", "양초", ["거실 구석에 양초가 있다.", "양초를 찾았다!"]],
	["thread", "실", ["???의 방에 실이 있다.", "실을 찾았다!"]],
	["pencils", "색연필", ["상자 사이에 색연필이 있다.", "색연필을 찾았다!"]],
]


static func objectives() -> Array:
	match Game.step:
		0: return [["???에게 퀘스트 받기", false]]
		1: return ITEMS.map(func(it): return [it[1] + " 찾기", Game.flags.get(it[0], false)])
		2: return [["tHE shop에서 사탕 사 먹기", false]]
		_: return [["집에 가서 자기", false]]


static func marker_char() -> String: return {2: "S", 3: "H"}.get(Game.step, "")
static func whispers_on() -> bool: return Game.step <= 2
static func map_ready() -> bool: return true
static func can_sleep() -> bool: return Game.step == 3
static func on_step(_world) -> void: pass


static func on_enter(world) -> void:
	var tree: SceneTree = world.get_tree()
	if Game.map == "guide_home":
		_restore(world)
		if not Game.flags.get("guide_home_seen"):
			Game.flags.guide_home_seen = true
			await tree.create_timer(0.6).timeout
			await UI.say("", ["...여기가 ???의 집?", "아무도 없다.", "양초, 색연필, 실을 찾아보자."])
	elif Game.map == "home" and Game.step == 0 and not Game.flags.get("hello"):
		Game.flags.hello = true
		await tree.create_timer(0.8).timeout
		await UI.say("", ["......", "화면이 조금 어둡다.", "하늘도... 어제보다 어두운 것 같다.", "...기분 탓이겠지."])
		await tree.create_timer(0.6).timeout
		Game.whisper_now()
		await tree.create_timer(1.8).timeout
		await UI.say("", ["...또 뭔가 들렸다.", "무슨 말인지는 모르겠다.", "...신경 쓰지 말자."])
		await UI.say(GUIDE, ["좋은 아침!", "3일차에 온 걸 환영해.", "오늘 퀘스트는 조금 특별해. 이리 와 봐!"])
	elif Game.map == "home" and Game.step == 2 and not Game.flags.get("back_home"):
		Game.flags.back_home = true
		await tree.create_timer(0.7).timeout
		await UI.say("", ["...!!", "...집이다.", "방금 ???의 집에 있었는데...", "......",
			"...뭐, 원래 이런 게임이니까.", "보상도 받았으니 사탕이나 사 먹으러 가자."])
	elif Game.map == "town" and not Game.flags.get("town_seen"):
		Game.flags.town_seen = true
		await tree.create_timer(0.5).timeout
		await UI.say("", ["...하늘이 어둑하다.", "...그래도 비는 안 올 것 같다."])


# ???의 집에 들어올 때: 이미 주운 물건은 없애고, 열린 문은 열어 둔다
static func _restore(world) -> void:
	for it in ITEMS:
		if Game.flags.get(it[0]):
			world.set_shown(it[0], false)
			world.set_walk(it[0], true)
	world.set_walk("storage_door", Game.flags.get("storage_open", false))
	world.set_shown("trapdoor", Game.flags.get("trapdoor_seen", false))


static func door(ch: String) -> bool:
	if Game.map == "home" and ch == "D" and Game.step == 0:
		await UI.say(GUIDE, ["어디 가? 오늘 퀘스트부터 받아 가!"])
		return false
	return true


static func interact(id: String, world) -> bool:
	var f := Game.flags
	match id:
		"guide": await _guide(world)
		"istrue": await _istrue(world)
		"candle", "thread", "pencils":
			if f.get(id):
				return false
			await _pick(id, world)
		"storage_door":
			if f.get("storage_open"):
				await UI.say("", ["창고 문이 열려 있다."])
			else:
				await UI.say("", ["창고 문이다.", "...잠겨 있다."])
		"front_door": await UI.say("", ["문이 열리지 않는다.", "...밖에서 잠긴 것 같다."])
		"guide_bed": await UI.say("", ["???의 침대다.", "이불이 너무 반듯하다.", "...아무도 잔 적이 없는 것 같다."])
		"guide_desk": await UI.say("", ["책상 위에 그림이 있다.", "색연필로 그린 것 같다.", "...까만 사람이 그려져 있다."])
		"sofa": await UI.say("", ["소파다.", "앉은 자국이 하나도 없다."])
		"box": await UI.say("", ["상자다.", "...비어 있다."])
		"trapdoor": await UI.say("", ["지하실 문이다.", "...열지 말라고 했다."])
		"curtain", "window":
			if Game.map != "guide_home":
				return false
			await UI.say("", ["창문 밖이 새까맣다.", "...밤인가?"])
		_: return false
	return true


static func _pick(id: String, world) -> void:
	var f := Game.flags
	for it in ITEMS:
		if it[0] == id:
			await UI.say("", [it[2][0]])
			f[id] = true
			Game.items.append(id)
			world.set_shown(id, false)
			world.set_walk(id, true)
			Game.sfx("sfx_quest")
			UI.toast(it[2][1])
			UI.refresh()
	# 물건 하나 얻을 때마다 화면이 지직거린다
	await world.get_tree().create_timer(0.4).timeout
	UI.static_noise(0.5)
	world.shake()
	await world.get_tree().create_timer(0.7).timeout
	var found := ITEMS.filter(func(it): return f.get(it[0], false)).size()
	if found == 1:
		await UI.say("", ["...방금 화면이 지직거렸다.", "버그인가?"])
	elif found == 2 and not f.get("storage_open"):
		await world.get_tree().create_timer(0.6).timeout
		Game.sfx("sfx_door")
		f.storage_open = true
		world.set_walk("storage_door", true)
		await UI.say("", ["...철컥.", "어디선가 문이 열리는 소리가 났다.", "...창고 쪽이다."])
	elif found == 3:
		await _behind(world)


# 마지막 물건을 찾으면: 아무 소리 없이 ???가 뒤에 서 있다
static func _behind(world) -> void:
	var tree: SceneTree = world.get_tree()
	Game.whispers(false)
	Game.stop_bgm()
	await UI.say("", ["다 찾았다!", "이제 ???에게 가져다주면..."])
	await tree.create_timer(1.4).timeout
	var dirs := {"down": Vector2i.DOWN, "left": Vector2i.LEFT, "right": Vector2i.RIGHT, "up": Vector2i.UP}
	var turn: String = {"down": "up", "up": "down", "left": "right", "right": "left"}[world.facing]
	var back: Vector2i = world.cell + dirs[turn]
	if not world._walkable(back):  # 뒤가 벽이면 옆에라도
		for d in dirs:
			if d != world.facing and world._walkable(world.cell + dirs[d]):
				back = world.cell + dirs[d]
				turn = d
				break
	world.spawn_npc("guide", "guide", back)
	await tree.create_timer(1.6).timeout
	world.face(turn)
	world.shake()
	await UI.say("", ["...!!"])
	await tree.create_timer(0.5).timeout
	await UI.say(GUIDE, ["다 찾았네."])
	await UI.say(ME, ["깜짝이야!", "...언제 왔어?"])
	await UI.say(GUIDE, ["방금."])
	await UI.say("", ["...아무 소리도 안 났는데.", "......", "...하하. 뭐, 게임이니까."])
	Game.play_bgm(world.data.bgm, 0.8)
	await UI.say(GUIDE, ["내 물건 다 찾아 줘서 고마워!", "정말, 정말 고마워.", "자, 보상이야."])
	for it in ITEMS:
		Game.items.erase(it[0])
	Game.gold += 600
	Game.sfx("sfx_coin")
	UI.toast("600 골드를 받았다!")
	UI.refresh()
	await tree.create_timer(1.2).timeout

	# 창고 바닥의 지하실 문
	UI.static_noise(0.3)
	Game.flags.trapdoor_seen = true
	world.set_shown("trapdoor", true)
	await tree.create_timer(0.6).timeout
	await UI.say("", ["...어?", "창고 바닥에 문이 있다.", "...아까도 있었나?"])
	await UI.say(ME, ["저 문은 뭐야?"])
	await UI.say(GUIDE, ["아, 그거.", "......", "지하실이야.", "거기엔 \"그\"가 있어.", "절대 열지 마."])
	await UI.say(ME, ["\"그\"? \"그\"가 누군데?"])
	Game.stop_bgm()
	await tree.create_timer(0.8).timeout
	await UI.say(GUIDE, ["......", "\"무언가\"."])
	# 말할 새도 없이 집으로
	UI.static_noise(0.25)
	await UI.fade(true, 0.03)
	Game.step = 2
	UI.refresh()
	await tree.create_timer(0.6).timeout
	Game.go("home")


static func _guide(world) -> void:
	match Game.step:
		0:
			await UI.say(GUIDE, ["오늘의 퀘스트는...", "우리 집에서 물건 찾기!",
				"양초, 색연필, 실. 세 개만 찾아 주면 돼.", "내가 자꾸 어디 뒀는지 까먹거든."])
			if await UI.choose(GUIDE, "퀘스트를 수락할래?", ["수락", "...조금 이따가"]) != 0:
				await UI.say(GUIDE, ["그래. 기다릴게.", "...계속 기다릴게."])
				return
			await UI.say(GUIDE, ["고마워! 그럼 바로 보내 줄게."])
			Game.step = 1
			Game.sfx("sfx_quest")
			UI.toast("새 퀘스트!")
			UI.refresh()
			Game.stop_bgm()
			await UI.fade(true, 0.5)
			UI.hud(false)
			await UI.loading(2.4)
			Game.go("guide_home")
		2:
			await UI.say(GUIDE, ["왜 그렇게 봐?"])
			if await UI.choose(ME, "(뭐라고 하지?)", ["아까 그 지하실...", "...아니야"]) == 0:
				await UI.say(GUIDE, ["지하실?", "무슨 지하실?", "......", "tHE shop 가서 사탕이나 사 먹어. 오늘 많이 벌었잖아."])
			else:
				await UI.say(GUIDE, ["tHE shop 가서 사탕 사 먹어.", "오늘 많이 벌었잖아."])
		_: await UI.say(GUIDE, ["졸려 보이네.", "얼른 가서 자."])


static func _istrue(world) -> void:
	if Game.step != 2:
		await UI.say(SHOP, ["......", "오늘은 아직이야."] if Game.step < 2 else ["또 와.", "...내일도."])
		return
	await UI.say(SHOP, ["왔네.", "그 집에 다녀왔구나.", "......", "어서 와. 어서 와."])
	while true:
		match await UI.choose(SHOP, "뭘 줄까?", ["사탕  10G", "망치  100G", "그만두기"]):
			0:
				if Game.gold < 10:
					await UI.say(SHOP, ["돈이 모자라.", "...이상하네. 분명 있었을 텐데."])
					continue
				Game.gold -= 10
				Game.sfx("sfx_coin")
				UI.refresh()
				await UI.say(SHOP, ["사탕.", "오늘도 사탕이구나.", "......", "문은 안 열었지?"])
				await UI.say("", ["사탕을 먹었다.", "...달다.", "......", "또 졸음이 쏟아진다."])
				Game.flags.drowsy = true
				Game.step = 3
				Game.whispers(false)
				world.set_tint()
				UI.refresh()
				world.refresh()
				return
			1: await UI.say(SHOP, ["...", "망치는 아직이야.", "...곧이야."])
			_:
				await UI.say(SHOP, ["또 와."])
				return
