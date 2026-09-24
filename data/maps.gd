# 맵 데이터. 글자 하나 = 16x16 칸 하나.
# 맵을 고치고 싶으면 글자만 바꾸면 된다 (모든 줄 길이는 같아야 함).
extends RefCounted

# 바닥 글자 -> [tiles.png 번호, 못 지나감?]
const TILES := {
	"x": [0, false],  # 미완성 타일 (일부러 남겨둔 것)
	",": [1, false], "=": [2, false], ".": [3, false], "#": [4, true],
	"Y": [5, true], "E": [6, true], "R": [7, true], "_": [8, false],
	"*": [9, false], "F": [10, true],
}

# 물건/캐릭터 글자 -> 정보. frame = objects.png 칸 번호, base = 밑에 깔 바닥 글자
const THINGS := {
	"C": {"id": "curtain", "frame": 0, "base": "#"},
	"W": {"id": "window", "frame": 2, "base": "#"},
	"B": {"id": "bed", "frame": 4},
	"T": {"id": "table", "frame": 14},
	"p": {"id": "plant", "frame": 15},
	"c": {"id": "counter", "frame": 7},
	"1": {"id": "shelf_candy", "frame": 8, "base": "#"},
	"2": {"id": "shelf_hammer", "frame": 9, "base": "#"},
	"s": {"id": "sign", "frame": 16},
	"D": {"id": "door", "frame": 6, "base": "#", "walk": true},
	"H": {"id": "door_home", "frame": 6, "base": "E", "walk": true},
	"S": {"id": "door_shop", "frame": 6, "base": "E", "walk": true},
	"N": {"id": "guide", "npc": "guide"},
	"I": {"id": "istrue", "npc": "istrue"},
	"P": {"id": "spawn", "walk": true},
}

# 문 연결: [이동할 맵, 도착할 문 글자, 문에서 몇 칸 떨어져 서는지]
const MAPS := {
	"home": {
		"bgm": "bgm_home", "floor": ".",
		"links": {"D": ["town", "H", Vector2i(0, 1)]},
		"rows": [
			"####################",
			"######C####W###xxxx#",
			"#..............xxxx#",
			"#.B............xx..#",
			"#..............x...#",
			"#......N...........#",
			"#.....T............#",
			"#..................#",
			"#.p.......P........#",
			"#..................#",
			"#########D##########",
		],
	},
	"town": {
		"bgm": "bgm_town", "floor": ",",
		"links": {"H": ["home", "D", Vector2i(0, -1)], "S": ["shop", "D", Vector2i(0, -1)]},
		"rows": [
			"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
			"xYYYYYYYYYYYYYYYYYYYYYYYYYYYxx",
			"xY,,,,,,,,,,,,,,,,,,,,,,,,,Yxx",
			"xY,RRRRR,,,,*,,,,,,,RRRRR,,Yxx",
			"xY,RRRRR,,,,,,,,*,,,RRRRR,,Yxx",
			"xY,EEHEE,,,,,,,,,,,,EESEE,,Yxx",
			"xY,,,=,,,,,,,,*,,,,,,,=,s,,Yxx",
			"xY,,,==================,,,,Yxx",
			"xY,*,,,,,,,,,=,,,,,,,,,,*,,Yxx",
			"xY,,,,FFFF,,,=,,,,Y,,,,,,,,Yxx",
			"xY,,,,,,,,,,,=,,,,,,,,*,,,,Yxx",
			"xY,,*,,,,,,,,=,,,,,,,,,,,,,Yxx",
			"xY,,,,,,,Y,,,=,,,*,,,,,,xxxYxx",
			"xYYYYYYYYYYYY=YYYYYYYYYxxxxxxx",
			"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
		],
	},
	"shop": {
		"bgm": "bgm_shop", "floor": "_",
		"links": {"D": ["town", "S", Vector2i(0, 1)]},
		"rows": [
			"####################",
			"#######1##2#########",
			"#xx______________xx#",
			"#x_______I_______xx#",
			"#_____cccccccc_____#",
			"#__________________#",
			"#__________________#",
			"#__________________#",
			"#_________P________#",
			"#__________________#",
			"#########D##########",
		],
	},
}
