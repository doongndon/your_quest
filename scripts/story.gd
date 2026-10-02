# 날짜별 이야기 파일(day1.gd, day2.gd ...)을 골라 주고, 날마다 똑같은 것(물건 설명, 하루 끝)을 맡는다.
# 새 날을 만들려면: dayN.gd 를 만들고 아래 DAYS 에 한 줄 추가.
extends RefCounted

const DAYS := [preload("res://scripts/day1.gd"), preload("res://scripts/day2.gd")]


static func cur() -> GDScript:
	return DAYS[Game.day - 1]


static func objectives() -> Array: return cur().objectives()
static func marker_char() -> String: return cur().marker_char()
static func door(ch: String) -> bool: return await cur().door(ch)
static func on_step(world) -> void: await cur().on_step(world)


static func on_enter(world) -> void:
	Game.whispers(cur().whispers_on())
	await cur().on_enter(world)


static func open_map() -> void:
	if cur().map_ready():
		UI.open_map()
	else:
		UI.toast("아직 지도가 없다.")


static func interact(id: String, world) -> void:
	if await cur().interact(id, world):
		return
	var f := Game.flags
	match id:  # 그날 이야기가 따로 처리하지 않은 물건들
		"curtain": await UI.say("", ["커튼이 쳐져 있다." if f.get("curtain") else "커튼이 열려 있다. 햇빛이 눈부시다."])
		"window": await UI.say("", ["창문이 열려 있다. 바람이 조금 분다." if f.get("window") else "창문이 닫혀 있다."])
		"bed":
			if cur().can_sleep():
				await sleep(world)
			else:
				await UI.say("", ["이불이 깔끔하다." if f.get("bed") else "아직 졸리지 않다."])
		"table": await UI.say("", ["책상이다. 위에 아무것도 없다.", "...아직 안 만든 것 같다."])
		"plant": await UI.say("", ["화분이다. 잎이 조금 네모나다."])
		"sign": await UI.say("", ["[ tHE shop ]", "글자가 이상하게 쓰여 있다."])
		"shelf_candy": await UI.say("", ["알록달록한 사탕이 있다."])
		"shelf_hammer": await UI.say("", ["망치가 있다.", "...슈퍼에 왜 망치가 있지?"])
		"istrue": await UI.say("ISTRUE", ["또 왔네.", "오늘은 더 팔 게 없어. 내일 와."])
		"guide": await UI.say("???", ["잘 자.", "내일 또 봐."])


# 침대에서 "잔다"를 고르면: N일차 끝 -> 다음 날 아침 (아직 없는 날이면 타이틀로)
static func sleep(world) -> void:
	if await UI.choose("", "잘까?", ["잔다", "아직"]) != 0:
		return
	Game.whispers(false)
	Game.stop_bgm()
	await UI.fade(true, 1.2)
	UI.hud(false)
	await UI.card("%d일차 끝" % Game.day, 1.6)
	Game.whisper_now(cur().NIGHT_WHISPER)
	await world.get_tree().create_timer(2.5).timeout
	Game.best_day = maxi(Game.best_day, Game.day)
	if Game.day < DAYS.size():
		Game.start_day(Game.day + 1)
		Game.save_game()
		await UI.card("%d일차" % Game.day, 1.4)
		Game.go("home")
	else:
		Game.save_game()
		await UI.card("%d일차는 아직 만드는 중이에요.\n플레이해 줘서 고마워요!" % (Game.day + 1), 2.4)
		world.get_tree().change_scene_to_file("res://scenes/title.tscn")
		UI.fade(false, 0.8)
