# 화면 위에 뜨는 모든 것: 대화창, 선택지, 퀘스트 목록, 골드, 지도, 페이드, 환청 글씨.
extends CanvasLayer

signal _next
signal _picked(i: int)

const Story := preload("res://scripts/story.gd")
const Maps := preload("res://data/maps.gd")
const FONT := preload("res://assets/fonts/Galmuri9.ttf")
const OBJ := preload("res://assets/sprites/objects.png")
const MAP_LABELS := {"S": "tHE shop", "H": "집", "G": "운동장"}
const TYPE_SPEED := 40.0  # 초당 글자 수
const TILE_COLORS := [Color("c800c8"), Color("6eb464"), Color("d6be8c"), Color("b07c52"), Color("ecdec4"),
	Color("346e40"), Color("c8aa8c"), Color("be5046"), Color("c8c8d0"), Color("6eb464"), Color("82583c")]

var busy := false
var player_cell := Vector2i(-1, -1)  # 지도에 표시할 주인공 위치 (마을에 있을 때만)

var _root := Control.new()
var _hud := Control.new()
var _quests := Label.new()
var _gold := Label.new()
var _bag := HBoxContainer.new()
var _box := PanelContainer.new()
var _name := Label.new()
var _text := Label.new()
var _more := Label.new()
var _choice := PanelContainer.new()
var _choice_list := VBoxContainer.new()
var _toast := Label.new()
var _whisper := Label.new()
var _noise := ColorRect.new()
var _fade := ColorRect.new()
var _card := Label.new()
var _map := Control.new()
var _typing := false
var _choosing := -1  # 선택 중인 번호 (-1 = 선택 중 아님)
var _options: Array = []


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	for f: FontFile in [FONT, preload("res://assets/fonts/Galmuri11.ttf")]:  # 픽셀 폰트를 선명하게
		f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		f.hinting = TextServer.HINTING_NONE
		f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	var theme := Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 10
	get_tree().root.theme = theme  # 모든 글씨에 픽셀 한글 폰트
	_root.theme = theme
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# HUD: 왼쪽 위 퀘스트, 오른쪽 위 골드/가방
	_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.hide()
	_root.add_child(_hud)
	_quests.position = Vector2(4, 2)
	_outline(_quests)
	_hud.add_child(_quests)
	var coin := TextureRect.new()
	coin.texture = icon(10)
	coin.position = Vector2(262, 2)
	_hud.add_child(coin)
	_gold.position = Vector2(279, 4)
	_outline(_gold)
	_hud.add_child(_gold)
	_bag.position = Vector2(262, 18)
	_hud.add_child(_bag)

	# 대화창
	_box.position = Vector2(4, 126)
	_box.size = Vector2(312, 50)
	_box.add_theme_stylebox_override("panel", _panel_style())
	_box.hide()
	_root.add_child(_box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	_box.add_child(v)
	_name.add_theme_color_override("font_color", Color("ffd96a"))
	v.add_child(_name)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(300, 0)
	v.add_child(_text)
	_more.text = "▼"
	_more.position = Vector2(305, 164)
	_root.add_child(_more)

	# 선택지
	_choice.add_theme_stylebox_override("panel", _panel_style())
	_choice.hide()
	_root.add_child(_choice)
	_choice.add_child(_choice_list)

	# 알림, 환청, 노이즈, 페이드, 큰 글씨 카드, 지도
	_toast.position = Vector2(0, 40)
	_toast.size = Vector2(320, 14)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_outline(_toast)
	_toast.modulate.a = 0
	_root.add_child(_toast)
	_whisper.add_theme_color_override("font_color", Color(0.85, 0.2, 0.25))
	_whisper.modulate.a = 0
	_root.add_child(_whisper)
	_noise.set_anchors_preset(Control.PRESET_FULL_RECT)
	_noise.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_noise.hide()
	_root.add_child(_noise)
	_map.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map.draw.connect(_draw_map)
	_map.hide()
	_root.add_child(_map)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.color = Color.BLACK
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0
	_root.add_child(_fade)
	_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	_card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_card.modulate.a = 0
	_root.add_child(_card)
	# 대화창이 카드/페이드 위에 보이도록 맨 위로
	for n in [_box, _more, _choice]:
		_root.move_child(n, -1)


func icon(frame: int) -> AtlasTexture:
	var t := AtlasTexture.new()
	t.atlas = OBJ
	t.region = Rect2((frame % 16) * 16, (frame / 16) * 16, 16, 16)
	return t


func _panel_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.1, 0.1, 0.16, 0.94)
	s.border_color = Color(0.94, 0.92, 0.86)
	s.set_border_width_all(1)
	s.set_content_margin_all(5)
	s.content_margin_top = 3
	return s


func _outline(l: Label) -> void:
	l.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.16))
	l.add_theme_constant_override("outline_size", 3)


func _process(delta: float) -> void:
	if _typing:
		var before := _text.visible_characters
		_text.visible_characters = mini(_text.get_total_character_count(), before + maxi(1, int(TYPE_SPEED * delta + 0.5)))
		if _text.visible_characters / 2 != before / 2:
			Game.sfx("sfx_blip", -8.0)
		_typing = _text.visible_characters < _text.get_total_character_count()
	_more.visible = _box.visible and not _typing and _choosing < 0 and fmod(Time.get_ticks_msec() / 400.0, 2.0) < 1.4


func _input(e: InputEvent) -> void:
	if _choosing >= 0:
		var d := int(e.is_action_pressed("down")) - int(e.is_action_pressed("up"))
		if d:
			_choosing = wrapi(_choosing + d, 0, _options.size())
			_draw_choices()
			Game.sfx("sfx_blip", -6.0)
		elif e.is_action_pressed("accept"):
			Game.sfx("sfx_select", -4.0)
			_picked.emit(_choosing)
		elif e.is_action_pressed("cancel"):
			_picked.emit(-1)
	elif _box.visible and (e.is_action_pressed("accept") or e.is_action_pressed("cancel")):
		if _typing:
			_text.visible_characters = -1
			_typing = false
		else:
			_next.emit()
	elif _map.visible and (e.is_action_pressed("map") or e.is_action_pressed("cancel") or e.is_action_pressed("accept")):
		_map.hide()
		_release.call_deferred()
	else:
		return
	get_viewport().set_input_as_handled()


func _release() -> void:
	await get_tree().process_frame
	busy = false


# ---------- 대화 ----------
func say(who: String, lines: Array) -> void:
	busy = true
	_name.text = who
	_name.visible = who != ""
	_box.show()
	for line in lines:
		_show_line(line)
		await _next
	_box.hide()
	await get_tree().process_frame
	busy = false


func _show_line(line: String) -> void:
	_text.text = line
	_text.visible_characters = 0
	_typing = true


# 선택지. 고른 번호를 돌려준다 (취소하면 -1)
func choose(who: String, prompt: String, options: Array) -> int:
	busy = true
	_name.text = who
	_name.visible = who != ""
	_box.show()
	_show_line(prompt)
	_options = options
	_choosing = 0
	_draw_choices()
	_choice.show()
	var i: int = await _picked
	_choosing = -1
	_choice.hide()
	_box.hide()
	await get_tree().process_frame
	busy = false
	return i


func _draw_choices() -> void:
	for c in _choice_list.get_children():
		c.free()
	for i in _options.size():
		var l := Label.new()
		l.text = ("> " if i == _choosing else "  ") + str(_options[i])
		if i == _choosing:
			l.add_theme_color_override("font_color", Color("ffd96a"))
		_choice_list.add_child(l)
	_choice.reset_size()
	_choice.position = Vector2(316 - _choice.get_combined_minimum_size().x, 122 - _choice.get_combined_minimum_size().y)


# ---------- HUD ----------
func hud(on: bool) -> void:
	_hud.visible = on
	refresh()


func refresh() -> void:
	var text := ""
	for q in Story.objectives():
		text += ("■ " if q[1] else "□ ") + q[0] + "\n"
	_quests.text = text
	_gold.text = str(Game.gold) + "G"
	for c in _bag.get_children():
		c.queue_free()
	for item in Game.items:
		var t := TextureRect.new()
		t.texture = icon({"candy": 11, "hammer": 12}.get(item, 10))
		_bag.add_child(t)


func toast(text: String) -> void:
	_toast.text = text
	var tw := create_tween()
	tw.tween_property(_toast, "modulate:a", 1.0, 0.15)
	tw.tween_interval(1.6)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.4)


func glitch(text: String) -> void:
	Game.sfx("sfx_glitch", -12.0)
	_whisper.text = text
	_whisper.position = Vector2(randi_range(20, 250), randi_range(30, 110))
	_noise.show()
	var tw := create_tween()
	for i in 3:
		tw.tween_callback(func(): _noise.color = Color(randf(), 0, randf(), 0.12))
		tw.tween_interval(0.05)
	tw.tween_callback(_noise.hide)
	tw.tween_property(_whisper, "modulate:a", 0.7, 0.3)
	for i in 6:
		tw.tween_callback(func(): _whisper.position += Vector2(randi_range(-1, 1), randi_range(-1, 1)))
		tw.tween_interval(0.2)
	tw.tween_property(_whisper, "modulate:a", 0.0, 0.6)


func fade(to_black: bool, time := 0.35) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0 if to_black else 0.0, time)
	await tw.finished


# 검은 화면에 큰 글씨 한 장
func card(text: String, hold := 2.0) -> void:
	busy = true
	_card.text = text
	var tw := create_tween()
	tw.tween_property(_card, "modulate:a", 1.0, 0.6)
	tw.tween_interval(hold)
	tw.tween_property(_card, "modulate:a", 0.0, 0.6)
	await tw.finished
	busy = false


# ---------- 지도 ----------
func open_map() -> void:
	busy = true
	_map.show()
	_map.queue_redraw()


func _draw_map() -> void:
	var rows: Array = Maps.MAPS.town.rows
	var cell := 6
	var origin := (Vector2(320, 180) - Vector2(rows[0].length(), rows.size()) * cell) / 2 + Vector2(0, 6)
	_map.draw_rect(Rect2(origin - Vector2(6, 18), Vector2(rows[0].length() * cell + 12, rows.size() * cell + 30)), Color(0.1, 0.1, 0.16, 0.95))
	_map.draw_string(FONT, origin + Vector2(0, -7), "지도   (M: 닫기)", HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
	for y in rows.size():
		for x in rows[y].length():
			var ch: String = rows[y][x]
			var t: Array = Maps.TILES.get(ch, Maps.TILES.get(Maps.THINGS.get(ch, {}).get("base", ","), [1]))
			var col: Color = Color("a07040") if ch in "HS" else TILE_COLORS[t[0]]
			_map.draw_rect(Rect2(origin + Vector2(x, y) * cell, Vector2(cell, cell)), col)
			if ch == Story.marker_char():
				_map.draw_texture_rect(icon(13), Rect2(origin + Vector2(x - 0.5, y - 2) * cell, Vector2(12, 12)), false)
				_map.draw_string(FONT, origin + Vector2(x + 1.5, y - 0.6) * cell, MAP_LABELS.get(ch, ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
	if Game.map == "town":
		_map.draw_rect(Rect2(origin + Vector2(player_cell) * cell + Vector2(1, 1), Vector2(4, 4)), Color("2b7bff"))
