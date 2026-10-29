#!/usr/bin/env python3
"""Extract a PDF's text into pack documents (Markdown), verbatim.

Only structure changes: headings are detected from font size (relative to
the body text) and become `## ` sections; lines are re-joined into
paragraphs; bullets become `- ` lines. Repeated page headers/footers and
page numbers are removed. Figure captions are kept and marked, because
diagrams themselves are not extracted (sections that depend on a figure
should be flagged for review).

A coverage check compares every word on the selected pages with the words
written (minus removed headers/footers) and reports any that went missing.

Text comes from pdfminer.six, which keeps word spacing intact (pypdf split
words like "car e" on Army manuals) and groups text into paragraph boxes.

Usage (python3 -m venv tools/.venv &&
tools/.venv/bin/pip install -r tools/packs/requirements.txt):

    tools/.venv/bin/python tools/packs/extract_pdf.py manual.pdf \\
        --source-url URL --title "Title" -o out.md \\
        [--pages 12-40] [--split-level 1|2] [--bold-headings] \\
        [--skip "Heading" ...] [--drop-line REGEX ...]

`--split-level 2` starts a new section at sub-headings too ("A: B").
`--pages` is 1-based and inclusive; repeat or comma-separate ranges.
"""

import argparse
import re
import sys
from collections import Counter

from pdfminer.high_level import extract_pages
from pdfminer.layout import LAParams, LTChar, LTTextBox, LTTextLine

BULLETS = "•●▪■◦○‣–"
SAFETY_LABEL = re.compile(r"^(warning|caution|danger|note)\b", re.I)
# A real caption: "Figure 5-5." / "Table A-1." — a number must follow, so
# running text like "Table 2-3 shows" (no period) or "table gives" isn't one.
FIGURE = re.compile(r"^(figure|fig\.|table)\s+[A-Z]?-?\d+(?:[-.]\d+)*[a-z]?\.(\s|$)", re.I)
PAGE_NUM = re.compile(
    r"^(page\s+)?[-–]?\s*([0-9]{1,3}|[ivxlc]{1,6}|[A-Z]?-?\d{1,3}-\d{1,3})\s*[-–]?$",
    re.I,
)


def parse_pages(spec, count):
    if not spec:
        return list(range(count))
    out = []
    for part in ",".join(spec).split(","):
        a, _, b = part.strip().partition("-")
        lo, hi = int(a), int(b or a)
        out.extend(range(lo - 1, min(hi, count)))
    return out


BREAK = ("", 0, False, False)  # paragraph boundary between text boxes
IMAGE = "\x00img:"  # line marker: an extracted figure/table goes here
MARGIN = 0.08  # top/bottom fraction of the page where headers/footers live


def clean(text):
    # (cid:N) is an unmapped glyph; in Army manuals cid:122 is the bullet.
    text = text.replace("(cid:122)", "•")
    return re.sub(r"\(cid:\d+\)", "", text)


def page_lines(layout, regions=()):
    """[(text, size, bold, in_margin)] per line, BREAK between boxes.

    in_margin marks lines in the top/bottom page band — the only place a
    line may be treated as a running header/footer. Repeated text anywhere
    else (e.g. table cells such as "Dial gauge") is content.
    """
    height = layout.height or 792
    lines = []
    placed = set()
    for box in layout:
        if not isinstance(box, LTTextBox):
            continue
        for line in box:
            if not isinstance(line, LTTextLine):
                continue
            # Skip invisible glyphs: Adobe's zero-width marker font and
            # sub-2pt characters (they put a stray "B" before ATP headings).
            visible = [
                o for o in line
                if not (
                    isinstance(o, LTChar)
                    and (o.size < 2 or "ZWAdobeF" in o.fontname)
                )
            ]
            chars = [
                c for c in visible
                if isinstance(c, LTChar) and c.get_text().strip()
            ]
            text = clean("".join(o.get_text() for o in visible).rstrip("\n"))
            if not text.strip() or not chars:
                continue
            size = Counter(round(c.size, 1) for c in chars).most_common(1)[0][0]
            bold = sum(
                1 for c in chars
                if re.search(r"bold|black|heavy|semibold", c.fontname, re.I)
            ) > len(chars) / 2
            in_margin = (
                line.y1 > height * (1 - MARGIN) or line.y0 < height * MARGIN
            )
            cx, cy = (line.x0 + line.x1) / 2, (line.y0 + line.y1) / 2
            region = next(
                (r for r in regions
                 if r["bbox"][0] <= cx <= r["bbox"][2]
                 and r["bbox"][1] <= cy <= r["bbox"][3]),
                None,
            )
            if region is not None:
                # Text inside a figure/table is shown by the image itself.
                if region["file"] not in placed:
                    placed.add(region["file"])
                    lines.append(BREAK)
                    lines.append((IMAGE + region["file"], 0, False, False))
                    lines.append(BREAK)
                continue
            lines.append((text, size, bold, in_margin))
        lines.append(BREAK)
    return lines


def norm(line):
    return re.sub(r"\s+", " ", line).strip()


def words(text):
    return re.findall(r"[a-z0-9]+", text.lower())


def build(path, pages, args):
    by_page = {}
    for fig in args.figure_index:
        by_page.setdefault(fig["page"] - 1, []).append(fig)
    raw = [
        page_lines(layout, by_page.get(pno, ()))
        for pno, layout in zip(
            pages, extract_pages(path, page_numbers=pages, laparams=LAParams())
        )
    ]

    # Body size = the size carrying the most characters.
    sizes = Counter()
    for lines in raw:
        for t, s, _, _ in lines:
            if t:
                sizes[s] += len(t)
    body = sizes.most_common(1)[0][0]

    # Header/footer lines: identical text (digits masked) on many pages.
    seen = Counter()
    for lines in raw:
        keys = {re.sub(r"\d+", "#", norm(t)) for t, _, _, m in lines if t and m}
        seen.update(keys)
    repeated = {k for k, n in seen.items() if n >= max(3, len(raw) * 0.3)}
    drop_res = [re.compile(r) for r in args.drop_line]

    def is_furniture(t, in_margin):
        n = norm(t)
        if not n:
            return True
        # Scan noise from figures (". .'T?", "V \\"): short, mostly symbols.
        if len(n) < 15 and sum(c.isalnum() for c in n) < max(3, len(n) * 0.5):
            return True
        if SAFETY_LABEL.match(n) or not in_margin:
            return False  # body text is never furniture, however repetitive
        return (
            PAGE_NUM.match(n)
            or re.sub(r"\d+", "#", n) in repeated
            or any(r.search(n) for r in drop_res)
        )

    kept_text, dropped_text, items = [], [], []
    # Inside a WARNING/CAUTION callout every line is body text: callout
    # bodies are often bold and would otherwise be mistaken for headings
    # (which turned warnings into section titles and lost the label).
    callout, callout_has_text = False, False
    for lines in raw:
        for t, s, b, m in lines:
            if not t:
                items.append(("break", ""))
                if callout and callout_has_text:
                    callout = False
                continue
            if t.startswith(IMAGE):
                items.append(("image", t[len(IMAGE):]))
                continue
            if is_furniture(t, m):
                dropped_text.append(t)
                continue
            kept_text.append(t)
            n = norm(t)
            # Captions and run-in labels ("CAUTION.", "Note:") are never
            # headings, whatever their font.
            label = FIGURE.match(n) or re.search(r"[.:,;]$", n)
            if SAFETY_LABEL.match(n):
                callout, callout_has_text = True, len(n) > 12
                kind = "label" if len(n) <= 12 else "text"
            elif callout:
                callout_has_text = True
                kind = "text"
            elif label:
                kind = "text"
            elif s >= body * 1.45:
                kind = "h1"
            elif s >= body * 1.15:
                kind = "h2"
            elif args.bold_headings and b and len(n) < 90:
                kind = "h2"
            elif (
                args.caps_headings
                and n.isupper()
                and 2 <= len(n.split()) <= 8
                and not re.search(r"\d", n)
            ):
                kind = "h2"
            else:
                kind = "text"
            items.append((kind, n))

    # Merge consecutive heading lines of the same level (wrapped headings).
    merged = []
    for kind, text in items:
        if merged and kind not in ("text", "break", "image") and merged[-1][0] == kind:
            merged[-1] = (kind, merged[-1][1] + " " + text)
        else:
            merged.append((kind, text))

    vocab = set(words(" ".join(kept_text)))
    return merged, body, kept_text, dropped_text, vocab


def join_line(prev, nxt, vocab):
    """Join wrapped lines; drop a hyphen only if the joined word is real."""
    if prev.endswith("-") and nxt[:1].islower():
        head = re.search(r"([A-Za-z]+)-$", prev)
        tail = re.match(r"([a-z]+)", nxt)
        if head and tail and (head.group(1) + tail.group(1)).lower() in vocab:
            return prev[:-1] + nxt
        return prev + nxt
    return prev + " " + nxt


def to_markdown(items, args, vocab):
    out = [f"# {args.title}", f"Source: {args.source_url}", ""]
    skip = {s.lower() for s in args.skip}
    # Without a top-level heading (one chapter per document), sub-headings
    # stand alone instead of being prefixed "Overview: …".
    h1, section, paras, skipping = None, "Overview", [], False
    para = None
    pending_label = None

    def end_para():
        nonlocal para
        if para:
            paras.append(para)
        para = None

    carried = []  # headings with no text of their own, never dropped

    def flush():
        end_para()
        body = "\n\n".join(paras).strip()
        if body and not skipping:
            lead = "".join(f"**{h}**\n\n" for h in carried)
            out.extend([f"## {section}", lead + body, ""])
            carried.clear()
        elif not body and not skipping and section != "Overview":
            carried.append(section)
        paras.clear()

    for kind, text in items:
        if kind == "break":
            if pending_label is None:
                end_para()
            continue
        if kind == "image":
            end_para()
            fig = args.figures_by_file[text]
            paras.append(f"![{fig['caption']}](img:{args.image_prefix}{fig['file']})")
            continue
        if kind == "label":
            end_para()
            pending_label = text.rstrip(".:")
            continue
        if pending_label is not None:
            # Attach the label to the callout text it introduces.
            text = f"**{pending_label.upper()}:** {text}"
            pending_label = None
            end_para()
            para = text
            continue
        if kind == "h1":
            flush()
            h1 = section = text
            skipping = text.lower() in skip
        elif kind == "h2":
            if args.split_level >= 2:
                flush()
                section = f"{h1}: {text}" if h1 else text
            else:
                end_para()
                paras.append(f"**{text}**")
        else:
            starts_item = text[:1] in BULLETS or re.match(r"^\d{1,2}[.)]\s", text)
            if FIGURE.match(text):
                end_para()
                if re.match(r"^table", text, re.I):
                    # Plain text cannot keep rows and columns together.
                    paras.append(
                        f"[{text} — table layout not preserved; verify "
                        "values against the original document]"
                    )
                else:
                    paras.append(f"[{text} — diagram not included]")
            elif starts_item:
                end_para()
                para = "- " + text.lstrip(BULLETS + " ")
            elif para is None:
                para = text
            elif re.search(r"[.!?:]$", para) and text[:1].isupper() and not para.startswith("- "):
                end_para()
                para = text
            else:
                para = join_line(para, text, vocab)
    flush()
    return "\n".join(out).rstrip() + "\n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("pdf")
    ap.add_argument("-o", "--out", required=True)
    ap.add_argument("--source-url", required=True)
    ap.add_argument("--title", required=True)
    ap.add_argument("--pages", nargs="*")
    ap.add_argument("--split-level", type=int, default=2)
    ap.add_argument("--bold-headings", action="store_true")
    ap.add_argument(
        "--caps-headings",
        action="store_true",
        help="treat short ALL-CAPS lines as headings (scanned books)",
    )
    ap.add_argument("--skip", nargs="*", default=[])
    ap.add_argument("--drop-line", nargs="*", default=[])
    ap.add_argument(
        "--figures",
        help="directory from extract_figures.py (index.json): text inside "
        "those regions is replaced by the image. 'auto' runs "
        "extract_figures.py into <out dir>/images/<out name>/ first.",
    )
    ap.add_argument("--table-caption", help="passed to extract_figures.py")
    args = ap.parse_args()

    args.figure_index, args.figures_by_file, args.image_prefix = [], {}, ""
    if args.figures == "auto":
        import os as _os
        import subprocess as _sp
        stem = _os.path.splitext(_os.path.basename(args.out))[0]
        args.figures = _os.path.join(_os.path.dirname(args.out), "images", stem)
        if _os.path.isdir(args.figures):
            import shutil as _sh
            _sh.rmtree(args.figures)
        cmd = [sys.executable, _os.path.join(_os.path.dirname(__file__), "extract_figures.py"),
               args.pdf, "--out", args.figures]
        if args.pages:
            cmd += ["--pages", *args.pages]
        if args.table_caption:
            cmd += ["--table-caption", args.table_caption]
        _sp.run(cmd, check=True)
    if args.figures:
        import json as _json
        import os as _os
        args.figure_index = _json.load(open(_os.path.join(args.figures, "index.json")))
        args.figures_by_file = {f["file"]: f for f in args.figure_index}
        # Image paths in markdown are relative to the pack's images/ dir.
        parts = _os.path.normpath(args.figures).split(_os.sep)
        args.image_prefix = parts[-1] + "/" if "images" in parts else ""
    from pdfminer.pdfpage import PDFPage
    with open(args.pdf, "rb") as f:
        count = sum(1 for _ in PDFPage.get_pages(f))
    pages = parse_pages(args.pages, count)
    items, body, kept, dropped, vocab = build(args.pdf, pages, args)
    md = to_markdown(items, args, vocab)

    # Coverage: words on kept lines must survive (hyphen joins allowed).
    out_words = set(words(md))
    lost = sorted(
        w for w in set(words(" ".join(kept))) - out_words
        if not any(w in o for o in out_words)
    )
    if lost:
        print(f"warning: words lost: {lost[:40]}", file=sys.stderr)
    open(args.out, "w", encoding="utf-8").write(md)
    print(
        f"wrote {args.out}: {md.count(chr(10) + '## ')} sections, "
        f"{len(md)} chars, body {body}pt, dropped {len(dropped)} header/footer lines"
    )


if __name__ == "__main__":
    main()
