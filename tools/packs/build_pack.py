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


def parse_document(path: Path) -> dict:
    lines = path.read_text(encoding="utf-8").splitlines()
    title, source, sections = None, None, []
    heading, body = None, []

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
        sections.extend(split_long(heading, text))

    for line in lines:
        if line.startswith("# ") and title is None:
            title = line[2:].strip()
        elif line.lower().startswith("source:") and heading is None:
            source = line.split(":", 1)[1].strip() or None
        elif line.startswith("## "):
            flush()
            heading, body = line[3:].strip(), []
        elif heading is not None:
            body.append(line)
    flush()

    if not title:
        raise PackError(f"{path.name}: missing '# Title' line")
    if not sections:
        raise PackError(f"{path.name}: no '## ' sections")
    doc = {"title": title, "sections": sections}
    if source:
        doc["sourceUrl"] = source
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

    docs = [parse_document(p) for p in sorted(src.glob("*.md"))]
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
    extra = f", {imgs} images" if imgs else ""
    print(f"wrote {out}: {len(pack['documents'])} documents, {n} sections{extra}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
