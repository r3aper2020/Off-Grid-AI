#!/usr/bin/env python3
"""Contact sheet of extracted figures/tables for review by eye.

    tools/.venv/bin/python tools/packs/contact_sheet.py content/<pack>/images/<doc> out.png

Every image must be reviewed before shipping: one figure per image, the
right caption, nothing cut off, nothing from a neighbouring figure.
"""
import json, os, sys
from PIL import Image, ImageDraw

src, out = sys.argv[1], sys.argv[2]
idx = json.load(open(os.path.join(src, "index.json")))
W, cols = 1500, 3
cell = W // cols - 12
thumbs = []
for i in idx:
    im = Image.open(os.path.join(src, i["file"])).convert("L")
    r = min(1.0, cell / im.width, 420 / im.height)
    t = im.resize((max(1, int(im.width * r)), max(1, int(im.height * r))))
    label = Image.new("L", (cell, 18), 255)
    ImageDraw.Draw(label).text((2, 2), f"{i['file']} p{i['page']}", fill=0)
    box = Image.new("L", (cell, t.height + 22), 200)
    box.paste(label, (0, 0)); box.paste(t, (0, 22))
    thumbs.append(box)
rows = [thumbs[k:k + cols] for k in range(0, len(thumbs), cols)]
H = sum(max(b.height for b in row) + 12 for row in rows) or 10
sheet = Image.new("L", (W, H), 120)
y = 0
for row in rows:
    x = 0
    for b in row:
        sheet.paste(b, (x, y)); x += cell + 12
    y += max(b.height for b in row) + 12
sheet.save(out)
print(f"{len(idx)} images -> {out} ({W}x{H})")
