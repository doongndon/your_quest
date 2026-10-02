# 임시(플레이스홀더) 그림/소리를 만드는 스크립트.
# 진짜 에셋을 받으면 같은 이름, 같은 크기로 덮어쓰기만 하면 된다.
# 실행: python3 tools/make_placeholders.py  (Pillow, numpy 필요)
import os, wave
import numpy as np
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..", "assets")
SPR = os.path.join(ROOT, "sprites")
AUD = os.path.join(ROOT, "audio")
os.makedirs(SPR, exist_ok=True)
os.makedirs(AUD, exist_ok=True)
rng = np.random.default_rng(7)

PAL = {
    "k": (43, 43, 58), "h": (90, 58, 42), "s": (242, 201, 160), "e": (43, 43, 58),
    "r": (232, 140, 140), "b": (74, 123, 208), "p": (58, 58, 90), "w": (240, 236, 228),
    "g": (126, 196, 120), "G": (84, 150, 90), "d": (30, 30, 36), "a": (180, 60, 70),
    "y": (240, 200, 70),
}


def from_rows(rows):
    img = Image.new("RGBA", (16, 16))
    for y, row in enumerate(rows):
        assert len(row) == 16, row
        for x, c in enumerate(row):
            if c in PAL:
                img.putpixel((x, y), PAL[c] + (255,))
    return img


def sheet(frames, cols):
    rows = (len(frames) + cols - 1) // cols
    out = Image.new("RGBA", (cols * 16, rows * 16))
    for i, f in enumerate(frames):
        out.paste(f, ((i % cols) * 16, (i // cols) * 16))
    return out


# ---------- 주인공: 64x64 (가로 4프레임 걷기 / 세로 아래,왼,오,위) ----------
TOP = ["................", "....kkkkkkkk....", "...khhhhhhhhk...", "..khhhhhhhhhhk.."]
FACE = {
    "down": ["..khhsssssshhk..", "..khsessssesh" "k..", "..khsrssssrshk..", "...kssssssssk..."],
    "up": ["..khhhhhhhhhhk..", "..khhhhhhhhhhk..", "..khhhhhhhhhhk..", "...khhhhhhhhk..."],
    "left": ["..khsssshhhhhk..", "..ksesshhhhhhk..", "..ksrsshhhhhhk..", "...ksssshhhhk..."],
}
FACE["right"] = [r[::-1] for r in FACE["left"]]
BODY = ["....kkkkkkkk....", "...kbbbbbbbbk...", "..ksbbbbbbbbsk..", "..ksbbbbbbbbsk..", "...kppppppppk..."]
STAND = ["...kppk..kppk...", "...kppk..kppk...", "...kkkk..kkkk..."]
LEGS = [STAND, ["...kppk..kppk...", "...kppk..kkkk...", "...kkkk........."],
        STAND, ["...kppk..kppk...", "...kkkk..kppk...", ".........kkkk..."]]
player = []
for d in ["down", "left", "right", "up"]:
    for f in range(4):
        rows = TOP + FACE[d] + BODY + LEGS[f]
        if f % 2:  # 걸을 때 1px 통통
            rows = rows[1:] + ["................"]
        player.append(from_rows(rows))
sheet(player, 4).save(os.path.join(SPR, "player.png"))

# ---------- 이름 없는 캐릭터: 32x16 (2프레임), 일부러 조잡하게 ----------
GUIDE = [
    "................", "................", "......kkkk......", "....kkggggkk....",
    "...kggggggggk...", "..kggwwggggggk..", "..kggwkgggwkgk..", "..kggggggggggk..",
    "..kgggkkkkgggk..", "..kggggggggggGk.", "...kgggggggGGk..", "...kGggggggGk...",
    "....kGGGGGGk....", "....kk....kk....", "................", "................",
]
g2 = ["................"] + GUIDE[:-1]
g2[6] = "..kggkwgggwkgk.."
sheet([from_rows(GUIDE), from_rows(g2)], 2).save(os.path.join(SPR, "guide.png"))

# ---------- ISTRUE (가게 주인): 32x16 (2프레임, 두번째는 눈이 이상함) ----------
IST = [
    "......kkkk......", ".....kddddk.....", "....kddddddk....", "....kwwwwwwk....",
    "....kwkwwkwk....", "....kwwwwwwk....", "....kwkkkkwk....", ".....kwwwwk.....",
    "....kaaaaaak....", "...kaaaaaaaak...", "...kwaaaaaawk...", "...kwaaaaaawk...",
    "....kaaaaaak....", "....kaaaaaak....", "....kkk..kkk....", "................",
]
i2 = list(IST)
i2[4] = "....kwwkkwwk...."
sheet([from_rows(IST), from_rows(i2)], 2).save(os.path.join(SPR, "istrue.png"))


# ---------- 바닥 타일: 256x16 (16x16 타일 가로로) ----------
def solid(c):
    return np.tile(np.array(c + (255,), np.uint8), (16, 16, 1))


def speckle(a, c, n):
    for _ in range(n):
        a[rng.integers(16), rng.integers(16)] = c + (255,)
    return a


def t_missing():  # "미완성" 느낌의 보라/검정 체크 (일부러)
    a = solid((0, 0, 0))
    for y in range(16):
        for x in range(16):
            if (x // 8 + y // 8) % 2 == 0:
                a[y, x] = (200, 0, 200, 255)
    return a


def t_grass():
    return speckle(solid((110, 180, 100)), (90, 160, 84), 22)


def t_path():
    return speckle(solid((214, 190, 140)), (190, 166, 118), 16)


def t_wood():
    a = solid((176, 124, 82))
    a[7] = a[15] = (140, 96, 62, 255)
    a[0:7, 5] = a[8:15, 12] = (150, 104, 68, 255)
    return a


def t_wall():
    a = solid((236, 222, 196))
    a[13:] = (150, 110, 80, 255)
    a[12] = (120, 88, 64, 255)
    return a


def t_tree():
    a = t_grass()
    yy, xx = np.mgrid[0:16, 0:16]
    m = (xx - 7.5) ** 2 + (yy - 6.5) ** 2 < 44
    a[m] = (52, 110, 64, 255)
    a[m & (rng.random((16, 16)) < .25)] = (70, 140, 80, 255)
    a[12:16, 6:10] = (110, 76, 50, 255)
    return a


def t_brick():
    a = solid((200, 170, 140))
    for y in (3, 7, 11, 15):
        a[y] = (160, 130, 104, 255)
    for y in range(16):
        a[y, 4 if (y // 4) % 2 else 12] = (160, 130, 104, 255)
    return a


def t_roof():
    a = solid((190, 80, 70))
    for y in (3, 7, 11, 15):
        a[y] = (150, 56, 52, 255)
    return a


def t_shopfloor():
    a = solid((200, 200, 208))
    for y in range(16):
        for x in range(16):
            if (x // 4 + y // 4) % 2:
                a[y, x] = (176, 176, 190, 255)
    return a


def t_flower():
    a = t_grass()
    for (x, y), c in zip([(3, 4), (11, 3), (7, 10), (13, 12), (2, 12)],
                         [(250, 240, 120), (250, 150, 180), (250, 250, 250), (250, 150, 180), (250, 240, 120)]):
        a[y, x] = c + (255,)
    return a


def t_fence():
    a = t_grass()
    a[5:7] = a[10:12] = (150, 106, 70, 255)
    a[3:14, 2:4] = a[3:14, 12:14] = (130, 90, 60, 255)
    return a


tiles = [t_missing, t_grass, t_path, t_wood, t_wall, t_tree, t_brick, t_roof, t_shopfloor, t_flower, t_fence]
Image.fromarray(np.hstack([f() for f in tiles] + [np.zeros((16, 16 * (16 - len(tiles)), 4), np.uint8)])).save(
    os.path.join(SPR, "tiles.png"))


# ---------- 물건: 256x32 (16x16 프레임, 가로 16개 x 2줄) ----------
def blank():
    return np.zeros((16, 16, 4), np.uint8)


def rect(a, x, y, w, h, c):
    a[y:y + h, x:x + w] = c + (255,)
    return a


def window(glass):
    a = rect(blank(), 2, 1, 12, 11, (110, 80, 60))
    rect(a, 3, 2, 10, 9, glass)
    rect(a, 7, 2, 2, 9, (110, 80, 60))
    return a


def curtain(closed):
    a = window((150, 200, 240))
    w = 5 if closed else 2
    rect(a, 2, 0, w, 13, (200, 90, 110))
    rect(a, 14 - w, 0, w, 13, (200, 90, 110))
    return rect(a, 1, 0, 14, 1, (90, 60, 50))


def bed(made):
    a = rect(blank(), 1, 0, 14, 16, (120, 80, 60))
    rect(a, 2, 1, 12, 4, (250, 250, 250))
    rect(a, 2, 5, 12, 10, (90, 140, 200))
    if not made:
        for y, x in [(6, 3), (7, 9), (9, 5), (10, 11), (12, 4), (13, 8)]:
            rect(a, x, y, 3, 1, (250, 250, 250))
    return a


def door():
    a = rect(blank(), 2, 0, 12, 16, (120, 80, 50))
    rect(a, 3, 1, 10, 15, (160, 110, 70))
    return rect(a, 10, 8, 2, 2, (240, 200, 70))


def counter():
    a = rect(blank(), 0, 2, 16, 14, (130, 90, 60))
    return rect(a, 0, 2, 16, 3, (180, 130, 90))


def shelf(item):
    a = rect(blank(), 1, 0, 14, 14, (120, 84, 56))
    rect(a, 2, 1, 12, 5, (70, 50, 36)); rect(a, 2, 7, 12, 6, (70, 50, 36))
    if item == "candy":
        for i, c in enumerate([(250, 120, 160), (120, 200, 250), (250, 220, 90), (160, 230, 140)]):
            rect(a, 3 + i * 3, 3, 2, 2, c); rect(a, 3 + i * 3, 10, 2, 2, c[::-1])
    else:
        rect(a, 4, 3, 8, 2, (150, 150, 160)); rect(a, 7, 5, 2, 1, (130, 90, 60))
        rect(a, 4, 9, 8, 2, (150, 150, 160)); rect(a, 7, 11, 2, 2, (130, 90, 60))
    return a


def coin():
    yy, xx = np.mgrid[0:16, 0:16]
    a = blank()
    a[(xx - 7.5) ** 2 + (yy - 7.5) ** 2 < 36] = (200, 150, 40, 255)
    a[(xx - 7.5) ** 2 + (yy - 7.5) ** 2 < 20] = (250, 210, 80, 255)
    return rect(a, 7, 5, 2, 6, (200, 150, 40))


def candy():
    a = blank()
    yy, xx = np.mgrid[0:16, 0:16]
    a[(xx - 7.5) ** 2 + (yy - 7.5) ** 2 < 14] = (250, 120, 160, 255)
    rect(a, 6, 6, 2, 2, (255, 230, 240))
    rect(a, 1, 5, 3, 6, (250, 170, 200)); rect(a, 12, 5, 3, 6, (250, 170, 200))
    return a


def hammer():
    a = rect(blank(), 3, 2, 10, 5, (150, 150, 160))
    rect(a, 3, 2, 10, 1, (200, 200, 210))
    return rect(a, 7, 7, 2, 8, (130, 90, 60))


def marker():
    a = blank()
    for y in range(8):
        rect(a, 1 + y, y + 2, 14 - 2 * y, 1, (230, 60, 60))
    return rect(a, 5, 0, 6, 2, (230, 60, 60))


def table():
    a = rect(blank(), 1, 3, 14, 9, (150, 104, 68))
    rect(a, 1, 3, 14, 2, (190, 140, 96))
    return rect(rect(a, 2, 12, 2, 4, (110, 76, 50)), 12, 12, 2, 4, (110, 76, 50))


def plant():
    a = rect(blank(), 5, 10, 6, 6, (170, 100, 70))
    for x, y in [(4, 4), (8, 2), (10, 6), (6, 7), (7, 5)]:
        rect(a, x, y, 3, 3, (80, 160, 90))
    return a


def sign():
    a = rect(blank(), 1, 2, 14, 8, (180, 130, 90))
    rect(a, 3, 4, 10, 1, (90, 60, 40)); rect(a, 3, 6, 7, 1, (90, 60, 40))
    return rect(a, 7, 10, 2, 6, (130, 90, 60))


objs = [curtain(False), curtain(True), window((150, 200, 240)), window((40, 40, 60)), bed(False), bed(True),
        door(), counter(), shelf("candy"), shelf("hammer"), coin(), candy(), hammer(), marker(), table(), plant(),
        sign()]
objs += [blank()] * (32 - len(objs))
Image.fromarray(np.vstack([np.hstack(objs[:16]), np.hstack(objs[16:])])).save(os.path.join(SPR, "objects.png"))

# ---------- "무언가": 32x32 (16x32 프레임 2개, 두번째는 지직거림) ----------
def something(glitch):
    a = np.zeros((32, 16, 4), np.uint8)
    body = (12, 10, 18)
    rect(a, 5, 2, 6, 7, body)             # 머리
    rect(a, 4, 9, 8, 12, body)            # 몸
    rect(a, 2, 10, 2, 13, body); rect(a, 12, 10, 2, 13, body)  # 긴 팔
    rect(a, 4, 21, 3, 11, body); rect(a, 9, 21, 3, 11, body)   # 다리
    rect(a, 6, 5, 1, 1, (255, 255, 255)); rect(a, 9, 5, 1, 1, (255, 255, 255))  # 눈
    if glitch:
        for y in (4, 12, 13, 22):
            a[y] = np.roll(a[y], 3 if y % 2 else -3, axis=0)
        a[5, 6] = a[5, 9] = (230, 40, 60, 255)
    return a


Image.fromarray(np.hstack([something(False), something(True)])).save(os.path.join(SPR, "something.png"))

# ---------- 소리 (임시 칩튠) ----------
SR = 22050


def save(name, x):
    x = np.clip(x, -1, 1)
    with wave.open(os.path.join(AUD, name + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x * 32000).astype("<i2").tobytes())


def note(freq, dur, kind="sine", vol=.3, decay=3.0):
    t = np.arange(int(SR * dur)) / SR
    if kind == "square":
        w = np.sign(np.sin(2 * np.pi * freq * t)) * .5
    elif kind == "tri":
        w = 2 * np.abs(2 * ((freq * t) % 1) - 1) - 1
    else:
        w = np.sin(2 * np.pi * freq * t) + .3 * np.sin(4 * np.pi * freq * t)
    env = np.exp(-decay * t) * np.minimum(1, t * 200)
    return w * env * vol


def hz(m):
    return 440 * 2 ** ((m - 69) / 12)


def song(chords, bpm, kind, seed, melody_oct=72):
    r = np.random.default_rng(seed)
    beat = 60 / bpm
    out = np.zeros(int(SR * beat * 4 * len(chords)) + SR)
    for i, ch in enumerate(chords):
        base = int(SR * beat * 4 * i)
        for b in range(4):  # 베이스
            n = note(hz(ch[0] - 12), beat, "tri", .18, 2)
            out[base + int(SR * beat * b):][:len(n)] += n
        for s in range(8):  # 멜로디 (코드 톤에서 고름)
            if r.random() < .7:
                n = note(hz(melody_oct + r.choice(ch) - 60 + 12 * (r.random() < .3)), beat * .9, kind, .12, 4)
                out[base + int(SR * beat * s / 2):][:len(n)] += n
    return out[:int(SR * beat * 4 * len(chords))]


save("bgm_home", song([[60, 64, 67], [57, 60, 64], [53, 57, 60], [55, 59, 62]] * 2, 84, "sine", 1))
save("bgm_town", song([[65, 69, 72], [60, 64, 67], [62, 65, 69], [55, 59, 62]] * 2, 96, "sine", 2))
save("bgm_shop", song([[57, 60, 64], [50, 53, 57], [52, 56, 59], [57, 60, 64]] * 2, 70, "sine", 3, 84))
save("sfx_blip", note(880, .04, "square", .15, 30))
save("sfx_select", note(1320, .06, "square", .15, 30))
save("sfx_quest", np.concatenate([note(hz(m), .09, "square", .2, 10) for m in (72, 76, 79, 84)]))
save("sfx_coin", np.concatenate([note(hz(83), .07, "square", .2, 10), note(hz(88), .25, "square", .2, 8)]))
t = np.arange(int(SR * .25)) / SR
save("sfx_door", rng.normal(0, .3, t.size) * np.exp(-12 * t))
t = np.arange(int(SR * 2.2)) / SR
noise = np.convolve(rng.normal(0, 1, t.size), np.ones(12) / 12, "same")
save("sfx_whisper", noise * (.5 + .5 * np.sin(2 * np.pi * 5 * t) ** 2) * np.sin(np.pi * t / t[-1]) * .5)
save("sfx_glitch", np.round(rng.normal(0, .5, int(SR * .15)) * 3) / 3 * .4)
save("bgm_field", song([[60, 64, 67], [65, 69, 72], [60, 64, 67], [55, 59, 62]] * 2, 110, "sine", 4))
t = np.arange(int(SR * .9)) / SR
save("sfx_rush", (rng.normal(0, .6, t.size) * np.minimum(1, t * 3) + np.sign(np.sin(2 * np.pi * (60 + 200 * t) * t)) * .3)
     * np.where(t < .75, 1, np.exp(-30 * (t - .75))))
print("done")
