# 4일차 이야기: 더 어두워진 세상, 가끔 지직거리는 화면, 말을 더듬는 ??? -> 마당 잡초 뽑기
# -> 잡초를 ???에게 -> 700 골드 -> 사탕 -> 졸음 -> 잠 -> 새벽에 깸 -> 창밖: ???가 ISTRUE에게 잡초를 준다 -> 다시 잠.
# Game.step: 0 퀘스트 받기 / 1 잡초 뽑기 / 2 ???에게 가져다주기 / 3 사탕 사 먹기 / 4 집에 가서 자기
#            5 (새벽) 창문 밖 보기 / 6 (새벽) 다시 자기
extends RefCounted

const GUIDE := "???"
const SHOP := "ISTRUE"
const ME := "나"
const NIGHT_WHISPER := "왜 깼어?"
const NIGHT_SOUND := false  # 밤마다 나던 환청 소리가 오늘은 음소거
const END_TEXT := "[ 4일차 클리어! ]"
const END_GLITCH := 2.0  # 3일차(1.0)보다 더 일그러진다
const TINT := Color(0.66, 0.64, 0.77)  # 3일차보다 더 어둡다
const CRACKLE := Vector2(3.0, 8.0)  # 화면이 3~8초마다 살짝 지직거린다
const DAWN := true  # 자고 나서 새벽에 한 번 깬다 (dawn 참고)
const WHISPERS := ["ㅇㅕ...ㄹ", "ㄴr...ㄱr", "ㄱ ㅡ ㄱ ㅏ", "ㅈ ㅏ ㅂ", "...ㅊㅗ", "ㅁ ㅜ ㅓ ㅅ", "ㅂ ㅘ ㅆ ㅇ ㅓ", "ㄲ ㅐ"]
const WHISPER_GAP := Vector2(8.0, 18.0)
const WEEDS := 6


static func objectives() -> Array:
	match Game.step:
		0: return [["???에게 퀘스트 받기", false]]
		1: return [["잡초 뽑기  (%d/%d)" % [Game.flags.get("pulled", []).size(), WEEDS], false]]
		2: return [["???에게 잡초 가져다주기", false]]
		3: return [["tHE shop에서 사탕 사 먹기", false]]
		4: return [["집에 가서 자기", false]]
		5: return [["......", false]]
		_: return [["다시 자기", false]]


static func marker_char() -> String:
	match Game.step:
		2: return "N" if Game.map == "home" else "H"
		3: return "S"
		4: return "H"
		5: return "" if Game.flags.get("peek") else "W"
		6: return "B"
	return ""


static func whispers_on() -> bool: return Game.step <= 3
static func map_ready() -> bool: return true
static func can_sleep() -> bool: return Game.step == 4 or Game.step == 6
static func on_step(_world) -> void: pass


static func on_enter(world) -> void:
	var tree: SceneTree = world.get_tree()
	var f := Game.flags
	if Game.map == "yard":
		for c in f.get("pulled", []):  # 이미 뽑은 잡초
			world.remove_at(c)
	if f.get("night") and Game.map == "home":
		world.set_shown("guide", false)  # ???는 밖에 나가 있다
		world.set_walk("guide", true)
	if Game.map == "yard" and f.get("peek"):
		await _peek(world)
	elif Game.map == "yard" and not f.get("yard_seen"):
		f.yard_seen = true
		await tree.create_timer(0.6).timeout
		await UI.say("", ["...마당이다.", "잡초가 여기저기 나 있다."])
	elif Game.map == "home" and Game.step == 0 and not f.get("hello"):
		f.hello = true
		await tree.create_timer(0.8).timeout
		await UI.say("", ["......", "어제보다 더 어둡다.", "하늘도, 그래픽도."])
		UI.static_noise(0.3, -12.0)
		await tree.create_timer(0.6).timeout
		await UI.say("", ["...화면도 조금 지직거린다.", "......", "...버그겠지.", "(대충 넘어가자.)"])
		await UI.say(GUIDE, ["조, 좋은 아침!", "이, 이리 와 봐!"])
		await UI.say("", ["...???가 말을 더듬는다.", "글리치 때문인 것 같다."])
	elif Game.map == "home" and Game.step == 5 and not f.get("woke"):
		f.woke = true
		await tree.create_timer(1.2).timeout
		await UI.say("", ["......", "...눈이 떠졌다.", "아직 깜깜하다. 새벽인가?"])
		await tree.create_timer(0.8).timeout
		Game.whisper_now("ㄲ ㅐ ㅆ ㄴ ㅔ", false)  # 소리가 안 난다
		await tree.create_timer(2.2).timeout
		await UI.say("", ["...?", "방금 뭔가 보였는데... 아무 소리도 안 났다.", "......", "???도 없다.",
			"...창문 밖에서 무슨 소리가 난다."])
	elif Game.map == "home" and Game.step == 6 and not f.get("back_bed"):
		f.back_bed = true
		await tree.create_timer(0.8).timeout
		await UI.say("", ["......", "...못 본 걸로 하자.", "다시 자자."])


static func door(ch: String) -> bool:
	if Game.map == "home" and ch == "D" and Game.step == 0:
		await UI.say(GUIDE, ["어, 어디 가? 퀘스트부터 받아 가!"])
		return false
	if Game.map == "home" and ch == "D" and Game.step >= 5:
		await UI.say("", ["...밖에 나가면 안 될 것 같다."])
		return false
	if Game.map == "yard" and ch == "H" and Game.step == 1:
		await UI.say("", ["아직 잡초가 남았다."])
		return false
	return true


static func interact(id: String, world) -> bool:
	match id:
		"guide": await _guide(world)
		"istrue": await _istrue(world)
		"weed":
			if Game.step != 1:
				return false
			await _pull(world)
		"window":
			if Game.step != 5:
				return false
			await UI.say("", ["창문 밖을 내다봤다."])
			Game.flags.peek = true
			world.moving = true
			Game.go("yard")
		_: return false
	return true


static func _pull(world) -> void:
	var f := Game.flags
	var pulled: Array = f.get("pulled", [])
	if pulled.is_empty():
		await UI.say("", ["잡초가 특이하게 생겼다.", "줄기 하나에... 길쭉한 잎이 다섯 장.", "잎마다 가시가 나 있다.", "...잡초 맞나?"])
		Game.items.append("weed")
	pulled.append(world.front())
	f.pulled = pulled
	world.remove_at(world.front())
	Game.sfx("sfx_quest")
	UI.toast("잡초를 뽑았다!  (%d/%d)" % [pulled.size(), WEEDS])
	UI.refresh()
	if pulled.size() >= WEEDS:
		Game.step = 2
		await world.get_tree().create_timer(0.8).timeout
		UI.toast("잡초를 다 뽑았다!  ???에게 가져다주자")
		UI.refresh()
		world.refresh()


static func _guide(world) -> void:
	match Game.step:
		0:
			await UI.say(GUIDE, ["오, 오늘의 퀘, 퀘스트는...", "마당에 잡초 뽑-뽑기!", "잡초가 너, 너무 많이 자랐거든.",
				"다 뽑아서 나, 나한테 갖다줘."])
			if await UI.choose(GUIDE, "퀘, 퀘스트를 수락할래?", ["수락", "...조금 이따가"]) != 0:
				await UI.say(GUIDE, ["기, 기다릴게."])
				return
			await UI.say(GUIDE, ["고, 고마워! 마당으로 보내 줄게."])
			Game.step = 1
			Game.sfx("sfx_quest")
			UI.toast("새 퀘스트!")
			UI.refresh()
			UI.static_noise(0.3)
			world.moving = true
			Game.go("yard")
		1: await UI.say(GUIDE, ["잡초는 마, 마당에 있어."])
		2:
			await UI.say(GUIDE, ["다, 다 뽑았어?", "줘, 줘 봐."])
			Game.items.erase("weed")
			UI.refresh()
			await UI.say("", ["???에게 잡초를 줬다.", "......", "(...잡초를 뭐 하러 가지려는 거지?)"])
			await UI.say(GUIDE, ["고마워. 저, 정말 고마워.", "보, 보상이야."])
			Game.gold += 700
			Game.sfx("sfx_coin")
			UI.toast("700 골드를 받았다!")
			await UI.say(GUIDE, ["tHE shop 가서 사, 사탕 사 먹어."])
			Game.step = 3
			UI.refresh()
			world.refresh()
		3: await UI.say(GUIDE, ["사, 사탕 먹고 와."])
		_: await UI.say(GUIDE, ["자, 잘 자."])


static func _istrue(world) -> void:
	if Game.step != 3:
		await UI.say(SHOP, ["......", "오늘은 아직이야."] if Game.step < 3 else ["또 와.", "...내일도."])
		return
	await UI.say(SHOP, ["왔네.", "...손에서 풀 냄새가 나네.", "......", "어서 와. 어서 와."])
	while true:
		match await UI.choose(SHOP, "뭘 줄까?", ["사탕  10G", "망치  100G", "그만두기"]):
			0:
				if Game.gold < 10:
					await UI.say(SHOP, ["돈이 모자라.", "...이상하네. 분명 있었을 텐데."])
					continue
				Game.gold -= 10
				Game.sfx("sfx_coin")
				UI.refresh()
				await UI.say(SHOP, ["사탕.", "오늘도 사탕이구나.", "푹 자.", "...푹."])
				await UI.say("", ["사탕을 먹었다.", "...달다.", "......", "졸음이 쏟아진다."])
				Game.flags.drowsy = true
				Game.step = 4
				Game.whispers(false)
				world.set_tint()
				UI.refresh()
				world.refresh()
				return
			1: await UI.say(SHOP, ["...", "망치는 아직이야.", "...거의 다 됐어."])
			_:
				await UI.say(SHOP, ["또 와."])
				return


# 잠들고 나서 (story.gd 의 sleep 이 부른다): 새벽에 깬다
static func dawn(world) -> void:
	Game.flags.drowsy = false
	Game.flags.night = true
	Game.step = 5
	await world.get_tree().create_timer(1.0).timeout
	await UI.card("......", 1.4)
	Game.go("home", "B")  # 침대 옆에서 깬다


# 창문 밖: ???가 ISTRUE에게 잡초를 준다
static func _peek(world) -> void:
	var tree: SceneTree = world.get_tree()
	world.player.visible = false
	var g: Sprite2D = world.spawn_npc("guide", "guide", Vector2i(8, 6))
	var s: Sprite2D = world.spawn_npc("istrue", "istrue", Vector2i(11, 6))
	await tree.create_timer(1.0).timeout
	await UI.say("", ["...마당에 누가 있다.", "......", "???다.", "그리고... ISTRUE?", "ISTRUE가 가게 밖에 있는 건 처음 본다."])
	var weed := Sprite2D.new()
	weed.texture = preload("res://assets/sprites/objects.png")
	weed.hframes = 16
	weed.vframes = 2
	weed.frame = 23
	weed.centered = false
	weed.position = g.position + Vector2(8, 2)
	world.add_child(weed)
	await tree.create_timer(0.8).timeout
	var tw: Tween = world.create_tween()
	tw.tween_property(weed, "position", s.position + Vector2(-8, 2), 1.4).set_trans(Tween.TRANS_SINE)
	await tw.finished
	await UI.say("", ["???가 ISTRUE에게 뭔가를 건넨다.", "......", "...아까 뽑은 잡초다."])
	weed.queue_free()
	await tree.create_timer(0.6).timeout
	await UI.say("", ["왜 잡초를... ISTRUE한테?"])
	await tree.create_timer(1.0).timeout
	UI.static_noise(0.3)
	await UI.say("", ["...!", "ISTRUE가 이쪽을 본 것 같다."])
	await UI.fade(true, 0.05)
	Game.flags.peek = false
	Game.step = 6
	await tree.create_timer(0.8).timeout
	Game.go("home", "B")
