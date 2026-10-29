#!/usr/bin/env python3
"""Extract chapters of a plain-text book (e.g. Project Gutenberg) verbatim.

Strips the Project Gutenberg header/footer (required for redistribution),
selects chapters by title, treats short ALL-CAPS lines as section headings,
re-joins wrapped lines into paragraphs, and marks illustrations as not
included. A coverage check reports any words lost.

Usage:
    python3 tools/packs/extract_text.py book.txt --chapter "WOODCRAFT" \\
        --title "Woodcraft (Boy Scouts Handbook, 1911)" \\
        --source-url URL -o out.md

`--chapter` matches the heading line after "CHAPTER <roman>" (case
insensitive); the chapter runs to the next "CHAPTER" heading.
"""

import argparse
import re
import sys

CHAPTER = re.compile(r"^CHAPTER\s+[IVXLC]+\.?\s*$", re.M)


def body_text(raw):
    raw = raw.replace("\r\n", "\n")
    start = re.search(r"^\*\*\* ?START OF.*$", raw, re.M)
    end = re.search(r"^\*\*\* ?END OF.*$", raw, re.M)
    return raw[start.end() if start else 0 : end.start() if end else len(raw)]


def find_chapter(text, name):
    heads = list(CHAPTER.finditer(text))
    # Search from the end: a table of contents repeats "CHAPTER II." with
    # the same titles before the real chapters.
    for i, m in reversed(list(enumerate(heads))):
        after = text[m.end():].lstrip("\n")
        title = after.split("\n", 1)[0].strip()
        if title.upper().startswith(name.upper()):
            stop = heads[i + 1].start() if i + 1 < len(heads) else len(text)
            return title, text[m.end():stop]
    sys.exit(f"chapter not found: {name}")


def is_heading(par):
    line = par.strip()
    return (
        "\n" not in line
        and line.isupper()
        and 1 <= len(line.split()) <= 10
        and re.search(r"[A-Z]{3}", line)
        and not line.startswith("[")
    )


def to_markdown(title, chapter_title, chunk, source):
    out = [f"# {title}", f"Source: {source}", ""]
    section, paras = chapter_title.title(), []

    def flush():
        if paras:
            out.extend([f"## {section}", "\n\n".join(paras), ""])
        paras.clear()

    for block in re.split(r"\n\s*\n", chunk):
        if not block.strip():
            continue
        text = re.sub(r"\s*\n\s*", " ", block.strip())
        if text.upper() == chapter_title.upper():
            continue
        if is_heading(block):
            flush()
            section = text.title()
            continue
        if text.startswith("[Illustration"):
            text = text.rstrip("]") + " — not included]"
        paras.append(text)
    flush()
    return "\n".join(out).rstrip() + "\n"


def words(s):
    return set(re.findall(r"[a-z0-9]+", s.lower()))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("book")
    ap.add_argument("--chapter", required=True)
    ap.add_argument("--title", required=True)
    ap.add_argument("--source-url", required=True)
    ap.add_argument("-o", "--out", required=True)
    a = ap.parse_args()

    text = body_text(open(a.book, encoding="utf-8").read())
    chapter_title, chunk = find_chapter(text, a.chapter)
    md = to_markdown(a.title, chapter_title, chunk, a.source_url)
    lost = sorted(words(chunk) - words(md) - {"not", "included"})
    if lost:
        print(f"warning: words lost: {lost[:30]}", file=sys.stderr)
    open(a.out, "w", encoding="utf-8").write(md)
    print(f"wrote {a.out}: {md.count(chr(10) + '## ')} sections, {len(md)} chars")


if __name__ == "__main__":
    main()
