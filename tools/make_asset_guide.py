# 그림 교체용 안내 그림(docs/asset_guide_*.png)을 만든다. 칸마다 번호와 이름을 붙여 크게 보여 준다.
# 실행: python3 tools/make_asset_guide.py  (Pillow 필요). 그림을 바꾼 뒤 다시 돌리면 안내 그림도 새로 그려진다.
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.join(os.path.dirname(__file__), "..")
SPR = os.path.join(ROOT, "assets", "sprites")
OUT = os.path.join(ROOT, "docs")
FONT = ImageFont.truetype(os.path.join(ROOT, "assets", "fonts", "Galmuri11.ttf"), 12)
Z = 4  # 확대 배율

# 파일 -> (칸 너비, 칸 높이, [칸 이름들])
SHEETS = {
    "objects.png": (16, 16, ["커튼 열림", "커튼 닫힘", "창문 닫힘", "창문 열림", "이불 흐트러짐", "이불 정리됨", "문", "계산대",
                             "선반 사탕", "선반 망치", "골드", "사탕", "망치", "목표 화살표", "책상", "화분",
                             "간판", "양초", "색연필", "실", "지하실 문", "상자", "소파", "잡초"]),
    "tiles.png": (16, 16, ["미완성(일부러)", "풀", "길/트랙", "나무 바닥", "벽", "나무", "벽돌", "지붕", "가게 바닥", "꽃", "울타리"]),
    "player.png": (16, 16, [f"{d} {i}" for d in ["아래", "왼쪽", "오른쪽", "위"] for i in ["서기", "걸음A", "서기", "걸음B"]]),
    "guide.png": (16, 16, ["숨쉬기 1", "숨쉬기 2"]),
    "istrue.png": (16, 16, ["평소", "가끔(눈 이상)"]),
    "something.png": (16, 32, ["평소", "지직"]),
}

for name, (fw, fh, labels) in SHEETS.items():
    img = Image.open(os.path.join(SPR, name)).convert("RGBA")
    cols = img.width // fw
    n = len(labels)
    per_row = min(cols, 8)
    cw, ch = max(fw * Z, 92) + 12, fh * Z + 24
    out = Image.new("RGB", (per_row * cw + 8, ((n + per_row - 1) // per_row) * ch + 30), (40, 40, 52))
    d = ImageDraw.Draw(out)
    d.text((8, 6), f"{name}  ({img.width}x{img.height}, 한 칸 {fw}x{fh})", font=FONT, fill=(255, 217, 106))
    for i, label in enumerate(labels):
        x, y = (i % cols) * fw, (i // cols) * fh
        cell = img.crop((x, y, x + fw, y + fh)).resize((fw * Z, fh * Z), Image.NEAREST)
        px, py = 8 + (i % per_row) * cw, 30 + (i // per_row) * ch
        bg = Image.new("RGBA", cell.size, (90, 90, 110, 255))
        for yy in range(0, cell.height, 8):  # 투명한 곳이 보이게 체크무늬
            for xx in range(0, cell.width, 8):
                if (xx + yy) // 8 % 2:
                    bg.paste((70, 70, 88, 255), (xx, yy, xx + 8, yy + 8))
        out.paste(Image.alpha_composite(bg, cell).convert("RGB"), (px, py))
        d.text((px, py + fh * Z + 3), f"{i}", font=FONT, fill=(255, 255, 255))
        d.text((px + 22, py + fh * Z + 3), label, font=FONT, fill=(200, 200, 215))
    out.save(os.path.join(OUT, "asset_guide_" + name))
print("done")
