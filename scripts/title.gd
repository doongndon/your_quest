# 타이틀 화면. 가짜 게임 정보(플레이 0, 후기 0)를 보여 주고 시작한다.
extends Control

var _menu := ["처음부터", "종료"]
var _sel := 0
var _items: Array[Label] = []
var _started := false


func _ready() -> void:
	UI.hud(false)
	Game.whispers(false)
	Game.crackle(false)
	Game.play_bgm("bgm_home", 0.9)
	var bg := ColorRect.new()
	bg.color = Color("1a1a28")
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)
	_label("YOUR QUEST", Vector2(0, 40), 20, Color("f0ece4"), preload("res://assets/fonts/Galmuri11.ttf"))
	_label("v0.1  (미완성)", Vector2(0, 66), 10, Color("8a8aa0"))
	if Game.best_day > 0:
		_menu.push_front("이어하기 (%d일차)" % Game.resume_day())
	_label("플레이 수 0명  ·  후기 0개" if Game.best_day == 0 else "%d일차 클리어!" % Game.best_day, Vector2(0, 162), 10, Color("5a5a70"))
	for i in _menu.size():
		_items.append(_label("", Vector2(0, 100 + i * 16), 10, Color.WHITE))
	_redraw()


func _label(text: String, pos: Vector2, size: int, color: Color, font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = Vector2(320, 16)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if font:
		l.add_theme_font_override("font", font)
	add_child(l)
	return l


func _redraw() -> void:
	for i in _items.size():
		_items[i].text = ("> %s <" if i == _sel else "%s") % _menu[i]
		_items[i].modulate = Color("ffd96a") if i == _sel else Color.WHITE


func _unhandled_input(e: InputEvent) -> void:
	if _started:
		return
	var d := int(e.is_action_pressed("down")) - int(e.is_action_pressed("up"))
	if d:
		_sel = wrapi(_sel + d, 0, _menu.size())
		Game.sfx("sfx_blip", -6.0)
		_redraw()
	elif e.is_action_pressed("accept"):
		Game.sfx("sfx_select")
		_started = true
		match _menu[_sel]:
			"종료": get_tree().quit()
			"처음부터": _intro()
			_: _continue()


func _intro() -> void:
	Game.stop_bgm()
	await UI.fade(true, 0.8)
	await UI.card("게임을 너무 못해서,\n쉬운 게임을 하나 깔았다.", 1.8)
	await UI.card("퀘스트를 깨기만 하면 되는 게임.\n플레이 수 0명, 후기 0개.", 1.8)
	await UI.card("...그래도 재미있어 보였다.", 1.4)
	Game.new_game()


func _continue() -> void:
	Game.stop_bgm()
	await UI.fade(true, 0.6)
	await UI.card("%d일차" % Game.resume_day(), 1.2)
	Game.continue_game()
