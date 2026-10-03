# 맵 하나를 그리고, 주인공을 칸 단위로 움직이고, 말 걸기/문 이동을 처리한다.
extends Node2D

const Maps := preload("res://data/maps.gd")
const Story := preload("res://scripts/story.gd")
const TILES_TEX := preload("res://assets/sprites/tiles.png")
const OBJ_TEX := preload("res://assets/sprites/objects.png")
const T := 16
const STEP_TIME := 0.17
const RUN_TIME := 0.09
const DROWSY_TIME := 0.28
const DIRS := {"down": Vector2i.DOWN, "left": Vector2i.LEFT, "right": Vector2i.RIGHT, "up": Vector2i.UP}
const ROW := {"down": 0, "left": 1, "right": 2, "up": 3}  # player.png 의 줄 순서

var data: Dictionary
var rows: Array
var size_cells: Vector2i
var things := {}   # 칸 -> {"id", "ch", "walk", "sprite"}
var npcs: Array[Sprite2D] = []
var player := Sprite2D.new()
var cell: Vector2i
var facing := "down"
var moving := false
var acting := false
var marker := Sprite2D.new()
var cam := Camera2D.new()
var tint := CanvasModulate.new()
var _step_count := 0


func _ready() -> void:
	data = Maps.MAPS[Game.map]
	rows = data.rows
	size_cells = Vector2i(rows[0].length(), rows.size())
	for y in size_cells.y:
		assert(rows[y].length() == size_cells.x, "맵 줄 길이가 다름: %s %d줄" % [Game.map, y])
		for x in size_cells.x:
			_place(rows[y][x], Vector2i(x, y))

	player.texture = preload("res://assets/sprites/player.png")
	player.hframes = 4
	player.vframes = 4
	player.centered = false
	add_child(player)
	cell = _find("P")
	if Game.arrive:
		cell = _find(Game.arrive) + _arrive_offset()
		facing = "down" if _arrive_offset().y > 0 else "up"
	_snap()

	marker.texture = OBJ_TEX
	marker.hframes = 16
	marker.vframes = 2
	marker.frame = 13
	marker.centered = false
	add_child(marker)
	var bob := create_tween().set_loops()
	bob.tween_property(marker, "offset:y", -3.0, 0.4)
	bob.tween_property(marker, "offset:y", 0.0, 0.4)

	var px := size_cells * T
	if px.x <= 320 and px.y <= 180:
		cam.position = Vector2(px) / 2  # 방 하나가 화면에 다 들어오면 고정
		add_child(cam)
	else:
		cam.position = Vector2(8, 8)
		cam.limit_right = px.x
		cam.limit_bottom = px.y
		player.add_child(cam)
	cam.limit_left = 0
	cam.limit_top = 0

	add_child(tint)
	set_tint()
	Game.play_bgm(data.bgm, data.get("pitch", 1.0))
	UI.hud(true)
	refresh()
	# 들어오자마자 나오는 이야기가 끝날 때까지는 못 움직인다 (대화가 겹치지 않게)
	acting = true
	await Story.on_enter(self)
	acting = false


func _place(ch: String, c: Vector2i) -> void:
	var def: Dictionary = Maps.THINGS.get(ch, {})
	if def.is_empty():
		return
	var s: Sprite2D
	if def.has("npc"):
		s = Sprite2D.new()
		s.texture = load("res://assets/sprites/%s.png" % def.npc)
		s.hframes = 2
		npcs.append(s)
	elif def.has("frame"):
		s = Sprite2D.new()
		s.texture = OBJ_TEX
		s.hframes = 16
		s.vframes = 2
		s.frame = def.frame
	if s:
		s.centered = false
		s.position = c * T
		add_child(s)
	things[c] = {"id": def.id, "ch": ch, "walk": def.get("walk", false), "sprite": s}


func _draw() -> void:
	for y in size_cells.y:
		for x in size_cells.x:
			var ch: String = rows[y][x]
			if not Maps.TILES.has(ch):
				ch = Maps.THINGS[ch].get("base", data.floor)
			draw_texture_rect_region(TILES_TEX, Rect2(x * T, y * T, T, T), Rect2(Maps.TILES[ch][0] * T, 0, T, T))


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for n in npcs:  # 조잡한 2프레임 숨쉬기 (ISTRUE 는 가끔만 눈이 바뀜)
		n.frame = int(fmod(t, 3.7) < 0.2) if "istrue" in n.texture.resource_path else int(t * 2) % 2
	if moving or acting or UI.busy or Game.travelling:
		return
	for d in DIRS:
		if Input.is_action_pressed(d):
			_walk(d)
			break


# 대화창이 먼저 키를 가져가므로, 여기엔 대화 중이 아닐 때 누른 키만 온다
func _unhandled_input(e: InputEvent) -> void:
	if moving or acting or UI.busy or Game.travelling:
		return
	if e.is_action_pressed("accept"):
		_interact()
	elif e.is_action_pressed("map"):
		Story.open_map()


func _walk(d: String) -> void:
	facing = d
	player.frame = ROW[d] * 4 + _step_count % 2 * 2
	var to: Vector2i = cell + DIRS[d]
	var th: Dictionary = things.get(to, {})
	if not _walkable(to):
		return
	moving = true
	var link: Array = data.links.get(th.get("ch", ""), [])
	if link:
		acting = true
		var ok: bool = await Story.door(th.ch)
		acting = false
		if not ok:
			moving = false
			return
	player.frame = ROW[d] * 4 + (_step_count * 2 + 1) % 4
	var tw := create_tween()
	var time := STEP_TIME
	if Game.flags.get("drowsy"):
		time = DROWSY_TIME
	elif Input.is_action_pressed("run"):
		time = RUN_TIME
	tw.tween_property(player, "position", Vector2(to * T), time)
	await tw.finished
	_step_count += 1
	cell = to
	player.frame = ROW[d] * 4 + (_step_count * 2) % 4
	UI.player_cell = cell
	if link:
		Game.sfx("sfx_door")
		Game.go(link[0], link[1])
		return
	await Story.on_step(self)
	moving = false


func _walkable(c: Vector2i) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= size_cells.x or c.y >= size_cells.y:
		return false
	if things.has(c):
		return things[c].walk
	return not Maps.TILES[rows[c.y][c.x]][1]


func _interact() -> void:
	var front: Vector2i = cell + DIRS[facing]
	var th: Dictionary = things.get(front, {})
	if th.get("id") == "counter":  # 계산대 너머에 있는 사람에게 말 걸기
		th = things.get(front + DIRS[facing], {})
	if th.is_empty() or th.id == "spawn" or (th.sprite and not th.sprite.visible):
		return
	acting = true
	await Story.interact(th.id, self)
	acting = false


func _find(ch: String) -> Vector2i:
	for c in things:
		if things[c].ch == ch:
			return c
	return Vector2i(size_cells / 2)


func _arrive_offset() -> Vector2i:
	for m in Maps.MAPS.values():
		for k in m.links:
			if m.links[k][0] == Game.map and m.links[k][1] == Game.arrive:
				return m.links[k][2]
	return Vector2i.DOWN


func _snap() -> void:
	player.position = cell * T
	player.frame = ROW[facing] * 4
	UI.player_cell = cell


# 물건 모양 바꾸기 (예: 커튼 열림 -> 닫힘)
func set_frame(id: String, frame: int) -> void:
	for th in things.values():
		if th.id == id and th.sprite:
			th.sprite.frame = frame


# 물건 보이기/숨기기 (예: 주운 물건 없애기)
func set_shown(id: String, on: bool) -> void:
	for th in things.values():
		if th.id == id and th.sprite:
			th.sprite.visible = on


# 물건 위로 지나갈 수 있는지 바꾸기 (예: 잠긴 문 열기)
func set_walk(id: String, on: bool) -> void:
	for th in things.values():
		if th.id == id:
			th.walk = on


func face(d: String) -> void:
	facing = d
	player.frame = ROW[d] * 4


# 맵에 없던 캐릭터를 c 칸에 세운다. 길을 막고, 숨쉬기도 한다.
func spawn_npc(npc: String, id: String, c: Vector2i) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load("res://assets/sprites/%s.png" % npc)
	s.hframes = 2
	s.centered = false
	s.position = c * T
	add_child(s)
	npcs.append(s)
	things[c] = {"id": id, "ch": "", "walk": false, "sprite": s}
	return s


# 목표 위에 빨간 화살표 띄우기
func refresh() -> void:
	var target: String = Story.marker_char()
	marker.visible = false
	for c in things:
		if things[c].ch == target:
			marker.position = (c + Vector2i.UP) * T
			marker.visible = true


# 세상 색: 그날의 어두움(Story.tint) x 졸음. 화면 위 글씨는 그대로.
# (CanvasModulate 는 한 화면에 하나만 써야 해서 하나로 합친다)
func set_tint() -> void:
	tint.color = Story.tint()
	if Game.flags.get("drowsy"):
		tint.color *= Color(0.72, 0.68, 0.82)


func shake() -> void:
	var tw := create_tween()
	for i in 8:
		tw.tween_property(cam, "offset", Vector2(randi_range(-4, 4), randi_range(-3, 3)), 0.04)
	tw.tween_property(cam, "offset", Vector2.ZERO, 0.04)
