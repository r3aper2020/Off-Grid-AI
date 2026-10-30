#!/usr/bin/env python3
"""Build an OFFGRID AI knowledge pack from Markdown sources.

A pack source directory looks like:

    content/<pack-id>/
      pack.json        metadata (id, title, category, version, publisher,
                       license, attribution, description)
      01-some-doc.md   one file per document, in filename order

Each document file:

    # Document title
    Source: https://example.gov/page

    ## Section heading
    Section text, copied verbatim from the source...

    ## Next section
    ...

Usage:
    python3 tools/packs/build_pack.py content/<pack-id> [-o assets/packs]

Output: <out>/<pack-id>.json in format `offgrid-pack` v1 (see
docs/knowledge-packs.md). Stdlib only; no network access.
"""

import argparse
import json
import re
import shutil
import sys
from pathlib import Path

FORMAT = "offgrid-pack"
FORMAT_VERSION = 1
CATEGORIES = {"guide", "medical", "map", "note"}
# Pack-level Survival Coverage Matrix status; absent means needs-review.
REVIEW = {"verified", "needs-review", "historical"}
REQUIRED = ["id", "title", "category", "version", "publisher", "license"]
ID_PATTERN = re.compile(r"^[a-z0-9][a-z0-9._-]{1,63}$")
# Sections much longer than this make poor citations; split them.
MAX_SECTION_CHARS = 4000
# Sections shorter than this (text only, images aside) are fragments —
# a stray caption line, a one-sentence intro — that pollute search and
# answer nothing on their own; they are merged into a neighbour.
MIN_SECTION_CHARS = 200
# Short words that are normal English, not OCR noise ("UJ cc", "z CJ").
COMMON_SHORT = set("a an as at be by do go he i if in is it me my no of on or "
                   "so to up us we am ok".split())
IMAGE_MARKER = re.compile(r"!\[([^\]]+)\]\(img:([^)\s]+)\)")


class PackError(Exception):
    pass


def split_long(heading: str, text: str) -> list:
    """Split an oversized section, never mid-paragraph: first at bold
    sub-heading paragraphs (`**Sub**` → "Heading: Sub"), then into
    numbered parts at paragraph breaks."""
    if len(text) <= MAX_SECTION_CHARS:
        return [{"heading": heading, "body": text}]

    paras = text.split("\n\n")
    groups, cur_head, cur = [], heading, []
    for para in paras:
        m = re.fullmatch(r"\*\*(.+)\*\*", para.strip())
        if m and cur:
            groups.append((cur_head, cur))
            cur_head, cur = f"{heading}: {m.group(1)}", []
        elif m:
            cur_head = f"{heading}: {m.group(1)}"
            continue
        if not m:
            cur.append(para)
    groups.append((cur_head, cur))

    out = []
    for head, ps in groups:
        chunks, buf = [], []
        for para in ps:
            if len(para) > MAX_SECTION_CHARS:
                raise PackError(f"'{head}': a single paragraph exceeds "
                                f"{MAX_SECTION_CHARS} chars; split the source")
            if buf and len("\n\n".join(buf + [para])) > MAX_SECTION_CHARS:
                chunks.append(buf)
                buf = []
            buf.append(para)
        if buf:
            chunks.append(buf)
        for i, c in enumerate(chunks):
            name = head if len(chunks) == 1 else f"{head} (part {i + 1})"
            out.append({"heading": name, "body": "\n\n".join(c)})
    return out


def text_only(body: str) -> str:
    """Section text without image markers (what search and the model see)."""
    return IMAGE_MARKER.sub(" ", body).strip()


def is_garbage(heading: str, body: str) -> bool:
    """OCR noise, diagram labels and table fragments: text that is not
    readable prose. Sections carrying an image are never garbage (the
    image is the content)."""
    if IMAGE_MARKER.search(body):
        return False
    text = text_only(body)
    words = re.findall(r"[A-Za-z]+", text)
    if not words:
        return True
    if len(words) < 12 and not re.search(r"[a-z]", text):
        return True  # an all-caps diagram label ("TAPED ON", "UJ cc")
    alpha = sum(len(w) for w in words) / max(1, len(text))
    if alpha < 0.4:
        return True  # mostly numbers/punctuation: an unpreserved table
    if text.count(".") > 0.15 * len(text):
        return True  # dot leaders: a table of contents
    noise = [w for w in words if len(w) <= 2 and w.lower() not in COMMON_SHORT]
    return len(words) < 60 and len(noise) > 0.3 * len(words)


def clean_sections(sections: list, report: list) -> list:
    """Drop garbage sections and merge fragments into a neighbour.

    A short intro ("Boil") merges forward into its first sub-section
    ("Boil: Steps…"); any other fragment merges backward into the previous
    section when the result stays under MAX_SECTION_CHARS, else forward.
    The fragment's heading survives as a bold line so it is still found.
    """
    kept = []
    for heading, body in sections:
        if is_garbage(heading, body):
            report.append(f"dropped '{heading[:50]}' ({len(body)} chars)")
        else:
            kept.append([heading, body])
    if not kept:
        return []

    def tiny(sec):
        return len(text_only(sec[1])) < MIN_SECTION_CHARS

    def joined(a, b, label):
        return f"{a}\n\n**{label}**\n\n{b}"

    changed = True
    while changed and len(kept) > 1:
        changed = False
        for i, sec in enumerate(kept):
            if not tiny(sec):
                continue
            nxt = kept[i + 1] if i + 1 < len(kept) else None
            prev = kept[i - 1] if i > 0 else None
            intro = (nxt and nxt[0].startswith(sec[0] + ": ")) or \
                sec[0].rstrip().endswith(":") or \
                text_only(sec[1]).rstrip().endswith(":")
            if nxt and intro and \
                    len(f"**{sec[0]}**\n\n{sec[1]}\n\n{nxt[1]}") <= MAX_SECTION_CHARS:
                # An intro ("For children:") belongs with what follows it,
                # never glued onto the unrelated section before it.
                nxt[1] = f"**{sec[0]}**\n\n{sec[1]}\n\n{nxt[1]}"
                report.append(f"merged '{sec[0][:50]}' into '{nxt[0][:50]}'")
            elif prev and len(joined(prev[1], sec[1], sec[0])) <= MAX_SECTION_CHARS:
                prev[1] = joined(prev[1], sec[1], sec[0])
                report.append(f"merged '{sec[0][:50]}' into '{prev[0][:50]}'")
            elif nxt and len(f"**{sec[0]}**\n\n{sec[1]}\n\n{nxt[1]}") <= MAX_SECTION_CHARS:
                nxt[1] = f"**{sec[0]}**\n\n{sec[1]}\n\n{nxt[1]}"
                report.append(f"merged '{sec[0][:50]}' into '{nxt[0][:50]}'")
            else:
                continue  # Neighbours are full: keep the fragment.
            del kept[i]
            changed = True
            break
    return [(h, b) for h, b in kept]


def parse_document(path: Path, report: list) -> dict:
    lines = path.read_text(encoding="utf-8").splitlines()
    title, source, aliases, library_only = None, None, None, False
    raw, heading, body = [], None, []

    def flush():
        if heading is None:
            return
        text = "\n".join(body).strip()
        text = re.sub(r"\n{3,}", "\n\n", text)
        if not text:
            raise PackError(f"{path.name}: section '{heading}' is empty")
        if "\ufffd" in text or "\ufffd" in heading:
            # Undecodable glyphs (e.g. a PDF font mapping spaces or degree
            # signs to nothing) mean the text is not verbatim. Never ship.
            raise PackError(
                f"{path.name}: section '{heading}' contains undecodable "
                "characters (\ufffd); fix the extraction before building"
            )
        raw.append((heading, text))

    for line in lines:
        if line.startswith("# ") and title is None:
            title = line[2:].strip()
        elif line.lower().startswith("source:") and heading is None:
            source = line.split(":", 1)[1].strip() or None
        elif line.lower().startswith("aliases:") and heading is None:
            # Retrieval-only plain-language phrasings (never shown).
            aliases = line.split(":", 1)[1].strip() or None
        elif line.lower().startswith("chat:") and heading is None:
            # "Chat: library-only" keeps a document (e.g. regulation text)
            # readable and searchable in the Library but out of AI answers.
            library_only = line.split(":", 1)[1].strip() == "library-only"
        elif line.startswith("## "):
            flush()
            heading, body = line[3:].strip(), []
        elif heading is not None:
            body.append(line)
    flush()

    if not title:
        raise PackError(f"{path.name}: missing '# Title' line")
    if not raw:
        raise PackError(f"{path.name}: no '## ' sections")
    doc_report = []
    split = []
    for h, text in clean_sections(raw, doc_report):
        split.extend(split_long(h, text))
    # Splitting at bold sub-headings can itself leave fragments (a figure
    # label between two headings), so clean once more.
    sections = [
        {"heading": h, "body": b}
        for h, b in clean_sections(
            [(s["heading"], s["body"]) for s in split], doc_report
        )
    ]
    if doc_report:
        report.append(f"{path.name}: {len(doc_report)} changes")
        report.extend("  " + r for r in doc_report)
    if not sections:
        raise PackError(f"{path.name}: nothing left after cleaning")
    doc = {"title": title, "sections": sections}
    if source:
        doc["sourceUrl"] = source
    if aliases:
        doc["aliases"] = aliases
    if library_only:
        doc["libraryOnly"] = True
    return doc


IMAGE = re.compile(r"!\[([^\]]+)\]\(img:([^)\s]+)\)")
IMAGES_DIR = Path("assets/packs/images")


def attach_images(pack_id: str, src: Path, pack: dict) -> int:
    """Move `![caption](img:doc/file.webp)` markers out of section text.

    Each section gets an "images" list (asset path, caption, kind) and its
    body keeps a short `{{img:N}}` placeholder, so file paths never pollute
    search. Image files are copied flat into assets/packs/images/.
    """
    IMAGES_DIR.mkdir(parents=True, exist_ok=True)
    count = 0
    kinds = {}
    for index in (src / "images").glob("*/index.json"):
        for fig in json.loads(index.read_text()):
            kinds[f"{index.parent.name}/{fig['file']}"] = fig.get("kind", "figure")
    for doc in pack["documents"]:
        for sec in doc["sections"]:
            images = []

            def repl(m):
                rel = m.group(2)
                file = src / "images" / rel
                if not file.exists():
                    raise PackError(f"missing image {file}")
                asset = IMAGES_DIR / f"{pack_id}--{rel.replace('/', '--')}"
                shutil.copyfile(file, asset)
                images.append({
                    "asset": asset.as_posix(),
                    "caption": m.group(1),
                    "kind": kinds.get(rel, "figure"),
                })
                return "{{img:%d}}" % (len(images) - 1)

            sec["body"] = IMAGE.sub(repl, sec["body"])
            if images:
                sec["images"] = images
                count += len(images)
    return count


def build(src: Path) -> dict:
    meta_path = src / "pack.json"
    if not meta_path.exists():
        raise PackError(f"{src}: missing pack.json")
    meta = json.loads(meta_path.read_text(encoding="utf-8"))
    missing = [k for k in REQUIRED if not str(meta.get(k, "")).strip()]
    if missing:
        raise PackError(f"pack.json missing: {', '.join(missing)}")
    if not ID_PATTERN.match(meta["id"]):
        raise PackError(f"invalid id {meta['id']!r}")
    if meta.get("review", "needs-review") not in REVIEW:
        raise PackError(f"review must be one of {sorted(REVIEW)}")
    if meta["category"] not in CATEGORIES:
        raise PackError(f"category must be one of {sorted(CATEGORIES)}")

    report = []
    docs = [parse_document(p, report) for p in sorted(src.glob("*.md"))]
    if report:
        print("\n".join(report), file=sys.stderr)
    if not docs:
        raise PackError(f"{src}: no .md documents")

    pack = {"format": FORMAT, "formatVersion": FORMAT_VERSION}
    for key in REQUIRED + ["description", "attribution", "review"]:
        if meta.get(key):
            pack[key] = meta[key]
    pack["documents"] = docs
    attach_images(meta["id"], src, pack)
    return pack


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[1])
    ap.add_argument("source", type=Path, help="pack source directory")
    ap.add_argument("-o", "--out", type=Path, default=Path("assets/packs"))
    args = ap.parse_args()
    try:
        pack = build(args.source)
    except (PackError, json.JSONDecodeError) as e:
        print(f"error: {e}", file=sys.stderr)
        return 1
    args.out.mkdir(parents=True, exist_ok=True)
    out = args.out / f"{pack['id']}.json"
    out.write_text(json.dumps(pack, ensure_ascii=False, indent=1) + "\n",
                   encoding="utf-8")
    n = sum(len(d["sections"]) for d in pack["documents"])
    imgs = sum(len(s.get("images", [])) for d in pack["documents"] for s in d["sections"])
    aliased = sum(1 for d in pack["documents"] if d.get("aliases"))
    extra = f", {imgs} images" if imgs else ""
    extra += f", {aliased}/{len(pack['documents'])} with aliases"
    print(f"wrote {out}: {len(pack['documents'])} documents, {n} sections{extra}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
