# 1일차 이야기. 대사를 고치고 싶으면 여기 글자만 바꾸면 된다.
# Game.step: 0 처음 / 1 퀘스트 중 / 2 보상 받기 / 3 tHE shop 가기 / 4 집으로 / 5 자기
extends RefCounted

const GUIDE := "???"
const SHOP := "ISTRUE"
const QUESTS := [["curtain", "커튼 치기"], ["window", "창문 열기"], ["bed", "이불 정리하기"]]


static func objectives() -> Array:
	match Game.step:
		0: return [["???와 이야기하기", false]]
		1: return QUESTS.map(func(q): return [q[1], Game.flags.get(q[0], false)])
		2: return [["???에게 돌아가기", false]]
		3: return [["tHE shop에서 물건 사기", false]]
		4: return [["집으로 돌아가기", false]]
		_: return [["침대에서 자기", false]]


static func marker_char() -> String:
	return {3: "S", 4: "H"}.get(Game.step, "")


static func on_enter(world) -> void:
	Game.whispers(Game.step >= 1 and Game.step <= 4)
	if Game.map == "home" and Game.step == 0 and not Game.flags.get("hello"):
		Game.flags.hello = true
		await world.get_tree().create_timer(0.6).timeout
		await UI.say(GUIDE, ["어! 거기 너!", "이리 와 봐! (방향키로 걷고, Z로 말 걸기)"])
	elif Game.map == "shop" and not Game.flags.get("shop_seen"):
		Game.flags.shop_seen = true
		await world.get_tree().create_timer(1.2).timeout
		Game.whisper_now("여기 아니야")


static func open_map() -> void:
	if Game.step < 3:
		UI.toast("아직 지도가 없다.")
	else:
		UI.open_map()


# 문에 들어가도 되는지. 안 되면 이유를 말해 준다.
static func door(ch: String) -> bool:
	if Game.map == "home" and ch == "D" and Game.step < 3:
		await UI.say(GUIDE, ["어디 가? 아직 퀘스트가 남았어!"])
		return false
	return true


static func interact(id: String, world) -> void:
	var f := Game.flags
	match id:
		"guide": await _guide(world)
		"istrue": await _istrue(world)
		"curtain":
			if Game.step == 1 and not f.get("curtain"):
				world.set_frame("curtain", 1)
				await _quest_done("curtain", world)
			else:
				await UI.say("", ["커튼이 쳐져 있다." if f.get("curtain") else "커튼이 열려 있다. 햇빛이 눈부시다."])
		"window":
			if Game.step == 1 and not f.get("window"):
				world.set_frame("window", 3)
				await _quest_done("window", world)
				await world.get_tree().create_timer(0.8).timeout
				Game.whisper_now("...거기 있어?")
				await world.get_tree().create_timer(1.6).timeout
				await UI.say("", ["...방금 뭔가 들린 것 같다.", "버그인가?"])
			else:
				await UI.say("", ["창문이 열려 있다. 바람이 조금 분다." if f.get("window") else "창문이 닫혀 있다."])
		"bed":
			if Game.step == 1 and not f.get("bed"):
				world.set_frame("bed", 5)
				await _quest_done("bed", world)
			elif Game.step == 5:
				if await UI.choose("", "잘까?", ["잔다", "아직"]) == 0:
					await _end_day(world)
			else:
				await UI.say("", ["이불이 깔끔하다." if f.get("bed") else "이불이 엉망이다."])
		"table": await UI.say("", ["책상이다. 위에 아무것도 없다.", "...아직 안 만든 것 같다."])
		"plant": await UI.say("", ["화분이다. 잎이 조금 네모나다."])
		"sign": await UI.say("", ["[ tHE shop ]", "글자가 이상하게 쓰여 있다."])
		"shelf_candy": await UI.say("", ["알록달록한 사탕이 있다."])
		"shelf_hammer": await UI.say("", ["망치가 있다.", "...슈퍼에 왜 망치가 있지?"])


static func _quest_done(key: String, world) -> void:
	Game.flags[key] = true
	Game.sfx("sfx_quest")
	for q in QUESTS:
		if q[0] == key:
			UI.toast("퀘스트 완료!  " + q[1])
	if QUESTS.all(func(q): return Game.flags.get(q[0], false)):
		Game.step = 2
		await world.get_tree().create_timer(1.0).timeout
		UI.toast("모든 퀘스트 완료!  ???에게 돌아가자")
	UI.refresh()


static func _guide(world) -> void:
	match Game.step:
		0:
			await UI.say(GUIDE, ["안녕! 드디어 누가 왔네!", "나? 나는... 이름은 아직 없어.", "그냥 편하게 불러.",
				"여기선 퀘스트를 깨면 돼. 엄청 쉬워!", "자, 첫 번째 퀘스트야!"])
			Game.step = 1
			Game.sfx("sfx_quest")
			UI.toast("새 퀘스트!")
			UI.refresh()
			Game.whispers(true)
			await UI.say(GUIDE, ["커튼 치기, 창문 열기, 이불 정리하기.", "할 수 있지?"])
		1: await UI.say(GUIDE, ["커튼 치기, 창문 열기, 이불 정리하기!", "천천히 해도 돼. 시간은 많으니까."])
		2:
			await UI.say(GUIDE, ["우와, 벌써 다 했어?", "역시! 너라면 할 줄 알았어.", "자, 보상이야!"])
			Game.gold += 30
			Game.sfx("sfx_coin")
			UI.toast("30 골드를 받았다!")
			UI.refresh()
			await UI.say(GUIDE, ["골드는 돈이야.", "tHE shop에 가면 물건을 살 수 있어.",
				"지도에 표시해 뒀어. (M 키로 지도 보기)", "문으로 나가면 돼. 다녀와!"])
			Game.step = 3
			UI.refresh()
			world.refresh()
		3: await UI.say(GUIDE, ["tHE shop은 밖으로 나가서 오른쪽이야.", "ISTRUE한테 안부 전해 줘."])
		4:
			await UI.say(GUIDE, ["왔구나! 뭐 샀어?", "...사탕!", "좋아. 아주 좋아.", "오늘은 이만 쉬자. 침대에서 자면 돼."])
			Game.step = 5
			Game.whispers(false)
			UI.refresh()
		_: await UI.say(GUIDE, ["잘 자.", "내일 또 봐."])


static func _istrue(world) -> void:
	if Game.step != 3:
		await UI.say(SHOP, ["또 왔네.", "오늘은 더 팔 게 없어. 내일 와."])
		return
	if not Game.flags.get("met_istrue"):
		Game.flags.met_istrue = true
		await UI.say(SHOP, ["어서 와.", "tHE shop에 온 걸 환영해.", "어서 와."])
	while true:
		match await UI.choose(SHOP, "뭘 줄까?", ["사탕  10G", "망치  100G", "그만두기"]):
			0:
				Game.gold -= 10
				Game.items.append("candy")
				Game.sfx("sfx_coin")
				UI.toast("사탕을 샀다!")
				UI.refresh()
				await UI.say(SHOP, ["사탕. 좋은 선택이야.", "정말로.", "정말로 좋은 선택이야."])
				Game.step = 4
				UI.refresh()
				world.refresh()
				await world.get_tree().create_timer(0.5).timeout
				Game.whisper_now("...먹지 마")
				return
			1: await UI.say(SHOP, ["그건 아직이야.", "나중에.", "나중에 필요할 거야."])
			_:
				await UI.say(SHOP, ["또 와."])
				return


static func _end_day(world) -> void:
	Game.whispers(false)
	Game.stop_bgm()
	await UI.fade(true, 1.2)
	UI.hud(false)
	await UI.card("1일차 끝", 1.6)
	Game.whisper_now("내일 또 와")
	await world.get_tree().create_timer(2.5).timeout
	await UI.card("2일차는 아직 만드는 중이에요.\n플레이해 줘서 고마워요!", 2.4)
	Game.best_day = maxi(Game.best_day, 1)
	Game.save_game()
	world.get_tree().change_scene_to_file("res://scenes/title.tscn")
	UI.fade(false, 0.8)
