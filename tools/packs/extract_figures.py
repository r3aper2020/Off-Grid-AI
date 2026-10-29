#!/usr/bin/env python3
"""Render a PDF's figures and tables as images, exactly as printed.

Text extraction can't keep diagrams, and scrambles tables (a processing
time can end up next to the wrong jar size). This tool finds each caption
("Figure 5-5. Fire lays", "Table 3. Process times…") and renders the
region of the original page that belongs to it, so the app can show the
real figure or table instead of a reconstruction.

Region detection: graphics (vector lines/curves/rects and embedded images)
plus the small text labels inside them, grouped by vertical proximity —
figures sit ABOVE their caption, tables BELOW (Army/USDA conventions;
override with --figure-caption-below / --table-caption-above).

Usage:
    tools/.venv/bin/python tools/packs/extract_figures.py doc.pdf \\
        --pages 117-134 --out content/<pack>/images/<doc> [--dpi 150]

Writes <slug>.webp per caption and index.json mapping caption → file.
Every image should be checked by eye before shipping (see --contact-sheet).
"""

import argparse
import json
import os
import re
import sys

import pypdfium2 as pdfium
from pdfminer.high_level import extract_pages
from pdfminer.layout import (LAParams, LTChar, LTCurve, LTFigure, LTImage,
                             LTLine, LTRect, LTTextBox, LTTextLine)

CAPTION = re.compile(r"^\s*(Figure|Fig\.|Table)\s+([A-Z]?-?\d+[\w.\-]*)\.?\s+(.{2,140})$", re.I)
GAP = 28  # points: max vertical gap within one figure/table


def parse_pages(spec, count):
    if not spec:
        return list(range(count))
    out = []
    for part in ",".join(spec).split(","):
        a, _, b = part.strip().partition("-")
        out.extend(range(int(a) - 1, min(int(b or a), count)))
    return out


def walk(obj):
    yield obj
    if hasattr(obj, "__iter__") and not isinstance(obj, LTTextLine):
        for child in obj:
            yield from walk(child)


def body_size(layout):
    sizes = {}
    for o in walk(layout):
        if isinstance(o, LTChar):
            s = round(o.size)
            sizes[s] = sizes.get(s, 0) + 1
    return max(sizes, key=sizes.get) if sizes else 10


def page_items(layout):
    """Graphics boxes and text boxes on a page (pdfminer coords)."""
    graphics, texts = [], []
    for o in walk(layout):
        if isinstance(o, (LTImage, LTCurve, LTLine, LTRect)) and o.width * o.height > 4:
            graphics.append(o.bbox)
        elif isinstance(o, LTFigure):
            graphics.append(o.bbox)
        elif isinstance(o, LTTextBox):
            texts.append(o)
    return graphics, texts


def grow(start_y, direction, graphics, labels, limit, span):
    """Union of graphics/labels contiguous from start_y going up (+1) or
    down (-1). Items must lie entirely on this side of `limit` (the next
    caption), so stacked tables never merge into one image, and must
    overlap the caption's column `span` (x0, x1), which excludes margin
    decorations such as chapter tabs."""
    x0, y0, x1, y1 = None, start_y, None, start_y
    cx0, cx1 = span[0] - 12, span[1] + 12
    items = sorted(
        (b for b in graphics + labels if b[2] > cx0 and b[0] < cx1),
        key=lambda b: b[1] if direction > 0 else -b[3],
    )
    edge = start_y
    for b in items:
        if direction > 0:
            if b[1] < start_y - 2 or b[3] > limit:
                continue
            if b[1] - edge > GAP:
                break
            edge = max(edge, b[3])
        else:
            if b[3] > start_y + 2 or b[1] < limit:
                continue
            if edge - b[3] > GAP:
                break
            edge = min(edge, b[1])
        x0 = b[0] if x0 is None else min(x0, b[0])
        x1 = b[2] if x1 is None else max(x1, b[2])
        y0, y1 = min(y0, b[1]), max(y1, b[3])
    return (x0, y0, x1, y1) if x0 is not None else None


def slug(kind, number):
    return f"{kind[:3].lower()}-{re.sub(r'[^a-z0-9]+', '-', number.lower()).strip('-')}"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("pdf")
    ap.add_argument("--pages", nargs="*")
    ap.add_argument("--out", required=True)
    ap.add_argument("--dpi", type=int, default=150)
    ap.add_argument(
        "--table-caption",
        help="extra regex for table captions without 'Table N' "
        "(e.g. USDA: '^Recommended process time')",
    )
    ap.add_argument("--figure-caption-below", action="store_true", default=True)
    ap.add_argument("--table-caption-above", action="store_true", default=True)
    args = ap.parse_args()

    os.makedirs(args.out, exist_ok=True)
    pdf = pdfium.PdfDocument(args.pdf)
    pages = parse_pages(args.pages, len(pdf))
    index, misses = [], []
    used = set()

    for pno, layout in zip(pages, extract_pages(args.pdf, page_numbers=pages, laparams=LAParams())):
        body = body_size(layout)
        graphics, texts = page_items(layout)
        captions = []
        extra = re.compile(args.table_caption, re.I) if args.table_caption else None
        for t in texts:
            text = " ".join(t.get_text().split())
            first = t.get_text().strip().split("\n")[0]
            m = CAPTION.match(first)
            if m:
                captions.append(
                    (t, m.group(1), m.group(2).rstrip("."), m.group(3).strip())
                )
            elif extra and extra.search(text):
                captions.append((t, "Table", f"p{pno + 1}-{len(captions) + 1}", text[:140]))
        if not captions:
            continue
        # Text column = extent of body-size text lines; anything outside
        # (chapter tabs, margin notes) is not part of a figure or table.
        body_boxes = [t.bbox for t in texts if len(t.get_text().strip()) > 60]
        column = (
            (min(b[0] for b in body_boxes), max(b[2] for b in body_boxes))
            if body_boxes else (0, layout.width)
        )
        # Short or small-font text boxes are labels inside figures/tables.
        caption_boxes = {id(c[0]) for c in captions}
        labels = []
        for t in texts:
            if id(t) in caption_boxes:
                continue
            chars = [c for c in walk(t) if isinstance(c, LTChar)]
            small = chars and sum(c.size for c in chars) / len(chars) < body * 0.97
            if small or len(t.get_text().strip()) < 60:
                labels.append(t.bbox)

        for t, kind, number, title in captions:
            is_table = kind.lower() == "table"
            # Stop at the neighbouring caption so stacked items stay apart.
            others = [c[0].bbox for c in captions if c[0] is not t]
            # The page's text column, not the caption's width: captions are
            # often narrower than their table (which clipped row labels).
            span = column
            if is_table:
                below = [b[3] for b in others if b[3] <= t.bbox[1] + 1]
                # Caption text sits inside a taller shaded bar; clear it.
                limit = max(below) + 6 if below else 0
                limit = max(limit, layout.height * 0.06)  # stay out of footers
                region = grow(t.bbox[1], -1, graphics, labels, limit, span)
            else:
                above = [b[1] for b in others if b[1] >= t.bbox[3] - 1]
                limit = min(above) - 6 if above else layout.height
                limit = min(limit, layout.height * 0.94)  # stay out of headers
                region = grow(t.bbox[3], +1, graphics, labels, limit, span)
            if not region:
                misses.append(f"p{pno + 1} {kind} {number}")
                continue
            # Include the caption itself so the image is self-describing.
            x0 = min(region[0], t.bbox[0]) - 6
            x1 = max(region[2], t.bbox[2]) + 6
            y0 = min(region[1], t.bbox[1]) - 6
            y1 = max(region[3], t.bbox[3]) + 6
            page = pdf[pno]
            w, h = page.get_size()
            # Padding must not reach into the neighbouring caption's bar.
            if is_table:
                y0 = max(y0, limit + 10)
            else:
                y1 = min(y1, limit - 10)
            x0, y0, x1, y1 = max(0, x0), max(0, y0), min(w, x1), min(h, y1)
            if x1 - x0 < 30 or y1 - y0 < 20:
                # Degenerate after clipping to neighbours: leave it as text.
                misses.append(f"p{pno + 1} {kind} {number} (region too small)")
                continue
            scale = args.dpi / 72
            bitmap = page.render(
                scale=scale,
                crop=(x0, y0, w - x1, h - y1),  # left, bottom, right, top
                grayscale=True,
            )
            name = slug(kind, number) + ".webp"
            if name in used:
                # "(continued)" pages share a number: never overwrite.
                name = f"{slug(kind, number)}-p{pno + 1}.webp"
            used.add(name)
            bitmap.to_pil().save(os.path.join(args.out, name), "WEBP", quality=70)
            label = title if number.startswith("p") else f"{kind} {number}. {title}"
            index.append({
                "file": name,
                "caption": label,
                "kind": "table" if is_table else "figure",
                "page": pno + 1,
                # PDF coordinates of the rendered region; extract_pdf.py
                # drops text inside it (labels, table cells) and puts the
                # image there instead.
                "bbox": [round(x0, 1), round(y0, 1), round(x1, 1), round(y1, 1)],
            })

    json.dump(index, open(os.path.join(args.out, "index.json"), "w"), indent=1)
    size = sum(os.path.getsize(os.path.join(args.out, i["file"])) for i in index)
    print(f"{len(index)} images ({size // 1024} KB) -> {args.out}")
    if misses:
        print(f"warning: no region found for: {misses}", file=sys.stderr)


if __name__ == "__main__":
    main()
