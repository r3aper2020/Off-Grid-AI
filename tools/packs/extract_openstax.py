#!/usr/bin/env python3
"""Turn OpenStax archive page JSON (REX "contents" API) into a pack document.

OpenStax serves every book section as JSON whose `content` field is the
section's XHTML with MathML equations:

    https://openstax.org/apps/archive/<archive>/contents/<book>@<ver>:<page>.json

The book JSON (`<book>@<ver>.json`) carries the `license` of that content
version and the page tree. This script writes one Markdown document from
one or more such page files, in order, as `## ` sections:

- top-level sections (`<section data-depth="1">`) become `## ` sections and
  their sub-sections bold lines (build_pack.py splits on those);
- text is copied verbatim; MathML is linearised to plain text
  (`V = IR`, `10^(-3)`, `R_1`, `(a)/(b)`) and placed inline or on its own
  line for display equations;
- tables become one line per row with ` | ` between cells;
- dropped: learning objectives, figures and their captions, Check Your
  Understanding exercises and answers, PhET/Link-to-Learning boxes,
  footnotes, equation numbers, glossary links.
  Worked examples are kept unless --drop-examples is given.

A word-coverage check reports how many words of the source prose (figures,
exercises and dropped boxes excluded) did not make it into the output.

Usage:
    python3 tools/packs/extract_openstax.py page1.json page2.json ... \\
        --title "..." --source-url URL [--aliases "phrase, phrase"] -o out.md \\
        [--drop-examples] [--drop-note "Title prefix" ...] [--drop-section REGEX ...]

Stdlib only.
"""

import argparse
import json
import re
import sys
import xml.etree.ElementTree as ET

XH = "{http://www.w3.org/1999/xhtml}"
MM = "{http://www.w3.org/1998/Math/MathML}"

# Note boxes that are interactive or off-topic for an offline reference.
DROP_NOTE_TITLES = (
    "PhET Explorations", "Link to Learning", "Answer:", "Career Connection",
    "Connections: Limits to Knowledge", "How Sciences Interconnect",
    "Take-Home Experiment: Virtual Solar Cells",
)
INVISIBLE = {"⁡", "⁢", "⁣", "⁤", "​", "‌", "‍", " ", " ", " ", "⁠"}


def tag(el):
    t = el.tag
    if t.startswith(XH):
        return t[len(XH):]
    if t.startswith(MM):
        return t[len(MM):]
    return t


def cls(el):
    return el.get("class", "")


# ----------------------------------------------------------------- MathML


def math_text(el):
    """Linearise a MathML element to plain text."""
    t = tag(el)
    kids = list(el)

    def join(parts):
        out = " ".join(p for p in parts if p)
        return re.sub(r"\s+", " ", out).strip()

    def wrap(s):
        s = re.sub(r"\s*/\s*", "/", s.strip())
        if re.fullmatch(r"[A-Za-z0-9.°′%μΩ/⋅Ͱ-Ͽ]+|[−-]?[0-9.]+", s):
            return s
        return f"({s})"

    if t in ("math", "mrow", "mstyle", "mpadded", "menclose", "semantics", "mtd", "mphantom"):
        if t == "semantics":
            kids = kids[:1]
        if t == "mphantom":
            return ""
        if t == "menclose" and "strike" in (el.get("notation") or ""):
            return ""          # struck-out (replaced) coefficient
        if t == "mrow":
            # a word spelled out as single-letter identifiers (<mi>u</mi><mi>n</mi>...)
            letters = [tag(k) == "mi" and len("".join(k.itertext()).strip()) == 1 for k in kids]
            if len(kids) >= 4 and all(letters):
                return "".join("".join(k.itertext()).strip() for k in kids)
        return join(math_text(k) for k in kids)
    if t in ("mi", "mn", "mo", "mtext", "ms"):
        s = "".join(el.itertext())
        s = "".join(ch for ch in s if ch not in INVISIBLE)
        return s.strip() if t != "mtext" else s.strip()
    if t == "mspace":
        return " "
    if t == "msup" and len(kids) == 2:
        return f"{wrap(math_text(kids[0]))}^{wrap(math_text(kids[1]))}"
    if t == "msub" and len(kids) == 2:
        return f"{wrap(math_text(kids[0]))}_{wrap(math_text(kids[1]))}"
    if t == "msubsup" and len(kids) == 3:
        return f"{wrap(math_text(kids[0]))}_{wrap(math_text(kids[1]))}^{wrap(math_text(kids[2]))}"
    if t == "mfrac" and len(kids) == 2:
        return f"{wrap(math_text(kids[0]))}/{wrap(math_text(kids[1]))}"
    if t == "msqrt":
        return f"sqrt({join(math_text(k) for k in kids)})"
    if t == "mroot" and len(kids) == 2:
        return f"root[{math_text(kids[1])}]({math_text(kids[0])})"
    if t in ("mover", "munder", "munderover") and kids:
        base = math_text(kids[0])
        acc = [math_text(k) for k in kids[1:]]
        acc = [a for a in acc if a and a not in ("¯", "‾", "→", "^", "˙", "⃗", "ˆ", "_", "̄")]
        return base if not acc else f"{base}[{' '.join(acc)}]"
    if t == "mfenced":
        o, c = el.get("open", "("), el.get("close", ")")
        sep = el.get("separators", ",").strip() or ","
        return f"{o}{(sep[0] + ' ').join(math_text(k) for k in kids)}{c}"
    if t == "mtable":
        rows = [math_text(k) for k in kids]
        return "; ".join(r for r in rows if r)
    if t == "mtr":
        return join(math_text(k) for k in kids)
    if t == "mmultiscripts":
        return join(math_text(k) for k in kids if tag(k) != "mprescripts")
    if t == "annotation" or t == "annotation-xml":
        return ""
    return join(math_text(k) for k in kids)


def tidy_math(s):
    s = re.sub(r"\s+", " ", s).strip()
    s = re.sub(r"\(\s+", "(", s)
    s = re.sub(r"\s+\)", ")", s)
    s = re.sub(r"\s+([,.;:])", r"\1", s)
    s = re.sub(r"\s*\^\s*", "^", s)
    s = re.sub(r"\s*_\s*", "_", s)
    s = re.sub(r"(\d)\. (\d)", r"\1.\2", s)      # <mn>12</mn><mo>.</mo><mn>0</mn>
    s = re.sub(r"(\d), (\d{3})\b", r"\1,\2", s)
    s = s.replace("()", "").replace("( )", "")
    s = re.sub(r"\(\s*(a q|a\s*q)\s*\)", "(aq)", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s


# --------------------------------------------------------------- document

BLOCK_TAGS = {"p", "div", "section", "ul", "ol", "table", "figure", "h1", "h2", "h3", "h4", "h5", "h6",
              "blockquote", "dl", "pre"}
BLOCK_TYPES = {"note", "example", "equation", "media", "exercise", "footnote"}


def is_block(el):
    return tag(el) in BLOCK_TAGS or (el.get("data-type") or "") in BLOCK_TYPES


def heading_text(el):
    return re.sub(r"\s+", " ", "".join(el.itertext())).strip()


class Doc:
    def __init__(self, drop_examples, drop_notes):
        self.sections = []      # [heading, [paragraph strings]]
        self.drop_examples = drop_examples
        self.drop_notes = tuple(DROP_NOTE_TITLES) + tuple(drop_notes)
        self.dropped = []       # (what, title)
        self.buf = []

    # ---- paragraphs
    def section(self, heading):
        self.flush()
        self.sections.append([heading, []])

    def para(self, text, keep_lines=False):
        text = re.sub(r"[ \t\r\f\v]+" if keep_lines else r"\s+", " ", text).strip()
        text = re.sub(r" +([,.;:)])", r"\1", text)
        text = re.sub(r"\( +", "(", text)
        if text:
            if not self.sections:
                self.section("")
            self.sections[-1][1].append(text)

    def flush(self):
        text = "".join(self.buf)
        self.buf = []
        if text.strip():
            self.para(text)

    # ---- inline
    def inline_text(self, el):
        """Text of an inline element (links, emphasis, terms, math)."""
        t = tag(el)
        dt = el.get("data-type") or ""
        if t == "math":
            s = tidy_math(math_text(el))
            return f" {s} " if s else ""
        role = el.get("role") or ""
        if dt in ("footnote-number", "footnote-ref") or "footnote" in role or role == "doc-noteref" \
                or el.get("{http://www.idpf.org/2007/ops}type") == "noteref":
            return ""
        if dt == "media" or t in ("img", "figure"):
            self.dropped.append(("figure", ""))
            return ""
        if t == "br" or dt == "newline":
            return " "
        if dt == "space":
            return " "
        parts = [el.text or ""]
        for k in el:
            if is_block(k):
                # a block nested in inline markup: flush what we have, emit it
                self.buf.append("".join(parts)); parts = []
                self.flush()
                self.block(k)
            else:
                parts.append(self.inline_text(k))
            parts.append(k.tail or "")
        return "".join(parts)

    def flow(self, el, skip_title=False):
        """Mixed inline/block content of a container, in document order."""
        if el.text:
            self.buf.append(el.text)
        for k in el:
            if skip_title and (k.get("data-type") == "title" or "os-title" in cls(k)):
                pass
            elif is_block(k):
                self.flush()
                self.block(k)
            else:
                self.buf.append(self.inline_text(k))
            if k.tail:
                self.buf.append(k.tail)

    def title_of(self, el):
        for k in el:
            if k.get("data-type") == "title" or (tag(k) in ("h2", "h3", "h4", "h5") and k.get("data-type") != "document-title"):
                return heading_text(k)
        return ""

    def example_title(self, el):
        for k in el.iter():
            if tag(k) == "h4" and k.get("data-type") == "title":
                return heading_text(k)
        return ""

    def list_items(self, el, depth=0):
        prefix = "  " * depth + "- "
        for li in el:
            if tag(li) != "li":
                continue
            text = [li.text or ""]
            sub = []
            for k in li:
                if tag(k) in ("ul", "ol"):
                    sub.append(k)
                elif is_block(k):
                    text.append(" " + "".join(self.collect(k)) + " ")
                else:
                    text.append(self.inline_text(k))
                text.append(k.tail or "")
            self.para(prefix + re.sub(r"\s+", " ", "".join(text)).strip())
            for s in sub:
                self.list_items(s, depth + 1)

    def collect(self, el):
        """Render a block (inside a list item or table cell) to one string."""
        saved_secs, saved_buf = self.sections, self.buf
        self.sections, self.buf = [["", []]], []
        self.block(el)
        self.flush()
        text = " ".join(p for _, ps in self.sections for p in ps)
        self.sections, self.buf = saved_secs, saved_buf
        return [text]

    def table(self, el):
        caption = ""
        rows = []
        for c in el:
            if tag(c) == "caption":
                caption = heading_text(c)
        for tr in el.iter():
            if tag(tr) != "tr":
                continue
            cells = []
            for c in tr:
                if tag(c) in ("td", "th"):
                    cells.append(re.sub(r"\s+", " ", "".join(self.collect(c))).strip())
            if any(cells):
                rows.append(" | ".join(cells))
        if caption:
            self.para(caption)
        if rows:
            # one paragraph, one line per row
            self.para("\n".join(rows), keep_lines=True)

    def example(self, el):
        title = self.example_title(el)
        if self.drop_examples:
            self.dropped.append(("example", title))
            return
        self.para(f"**Example: {title}**" if title else "**Example**")
        sec = self.sections[-1][1]
        start = len(sec) - 1
        body = next((k for k in el if tag(k) == "div" and cls(k) == "body"), el)
        if body.text:
            self.buf.append(body.text)
        for k in body:
            if tag(k) in ("h3", "h4", "h5") or k.get("data-type") == "title":
                if heading_text(k).startswith("Check Your Learning"):
                    self.dropped.append(("check your learning", title))
                    break
                # "Strategy", "Solution", "Discussion" labels: structural, not kept
            elif is_block(k):
                self.flush()
                self.block(k)
            else:
                self.buf.append(self.inline_text(k))
            if k.tail:
                self.buf.append(k.tail)
        self.flush()
        # A short example would be split off by its bold title and then dropped
        # as a fragment; keep it in the running text instead.
        if sum(len(p) for p in sec[start + 1:]) < 600:
            sec[start] = sec[start].strip("*")

    def block(self, el, depth=0):
        t = tag(el)
        dt = el.get("data-type") or ""
        c = cls(el)
        self.flush()

        if t == "figure" or dt == "media" or "os-figure" in c:
            self.dropped.append(("figure", ""))
            return
        if dt in ("exercise", "footnote", "footnote-refs") or el.get("role") == "doc-footnote":
            self.dropped.append((dt or "footnote", ""))
            return
        if "learning-objectives" in c or dt == "abstract":
            self.dropped.append(("learning objectives", ""))
            return
        if dt == "note":
            title = self.title_of(el)
            if any(title.startswith(p) for p in self.drop_notes):
                self.dropped.append(("note", title))
                return
            if title:
                self.para(f"**{title}**")
            self.flow(el, skip_title=True)
            self.flush()
            return
        if dt == "example":
            self.example(el)
            return
        if t == "section":
            title = self.title_of(el)
            d = int(el.get("data-depth", depth + 1) or depth + 1)
            if d <= 1 and title:
                self.section(title)
            elif title:
                self.para(f"**{title}**")
            self.flow(el, skip_title=True)
            self.flush()
            return
        if dt == "equation" or "equation" in c.split():
            for k in el:
                if tag(k) == "math":
                    self.para(tidy_math(math_text(k)))
                elif "os-equation-number" in cls(k):
                    pass
                else:
                    self.block(k, depth)
            return
        if "os-table" in c.split():
            for k in el:
                if "os-caption-container" in cls(k):
                    cap = " ".join(self.collect(k)).strip()
                    if cap:
                        self.para(cap)     # plain, so the table stays with its text
            for k in el:
                if tag(k) == "table":
                    self.table(k)
            return
        if t in ("ul", "ol"):
            self.list_items(el)
            return
        if t == "table":
            self.table(el)
            return
        if t in ("h1", "h2", "h3", "h4", "h5", "h6"):
            if dt == "document-title" or "os-title" in c:
                return
            title = heading_text(el)
            if title:
                self.para(f"**{title}**")
            return
        if t in ("head", "style", "script", "img"):
            return
        # p, div, blockquote, body, dl ...: mixed content
        self.flow(el)
        self.flush()


def page_title(root):
    for el in root.iter():
        if el.get("data-type") == "document-title":
            num = ""
            text = ""
            for s in el.iter():
                if "os-number" in cls(s):
                    num = "".join(s.itertext()).strip()
                if "os-text" in cls(s):
                    text = "".join(s.itertext()).strip()
            return f"{num} {text}".strip() if text else re.sub(r"\s+", " ", "".join(el.itertext())).strip()
    return ""


def words(text):
    return re.findall(r"[A-Za-z]{3,}", text.lower())


def source_words(root, doc):
    """Words of the prose we meant to keep (for the coverage check)."""
    out = []
    skip = set()
    for el in root.iter():
        dt = el.get("data-type") or ""
        c = cls(el)
        t = tag(el)
        if t == "figure" or dt in ("media", "exercise", "footnote", "abstract") or "learning-objectives" in c \
                or el.get("role") == "doc-footnote" or t == "math" or t in ("head", "style", "script") \
                or (dt == "note" and any(doc.title_of(el).startswith(p) for p in doc.drop_notes)) \
                or (dt == "example" and doc.drop_examples) or "os-equation-number" in c \
                or dt == "document-title" or (t == "h3" and "os-title" in c):
            for k in el.iter():
                skip.add(id(k))
            continue
        if id(el) in skip:
            continue
        if el.text:
            out += words(el.text)
        for k in el:
            if k.tail and id(el) not in skip:
                out += words(k.tail)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("pages", nargs="+")
    ap.add_argument("-o", "--out", required=True)
    ap.add_argument("--title", required=True)
    ap.add_argument("--source-url", required=True)
    ap.add_argument("--aliases", help="plain-language search phrasings (retrieval only, never shown)")
    ap.add_argument("--drop-examples", action="store_true")
    ap.add_argument("--drop-note", nargs="*", default=[], help="drop note boxes whose title starts with this")
    ap.add_argument("--drop-section", nargs="*", default=[], help="drop ## sections whose heading matches this regex")
    a = ap.parse_args()

    doc = Doc(a.drop_examples, a.drop_note)
    src_words = []
    for path in a.pages:
        data = json.load(open(path, encoding="utf-8"))
        root = ET.fromstring(data["content"])
        ptitle = page_title(root) or data.get("title", "")
        doc.section(ptitle)
        body = next(el for el in root.iter() if tag(el) == "body")
        doc.block(body)
        doc.flush()
        src_words += source_words(root, doc)

    # Drop empty sections; drop requested ones; merge a page-title section that
    # only holds the intro into the next section by keeping it (build_pack merges
    # short ones itself).
    secs = [(h, ps) for h, ps in doc.sections if ps]
    if a.drop_section:
        rx = [re.compile(p) for p in a.drop_section]
        secs = [(h, ps) for h, ps in secs if not any(r.search(h) for r in rx)]

    out = [f"# {a.title}", f"Source: {a.source_url}"]
    if a.aliases:
        out.append(f"Aliases: {a.aliases}")
    out.append("")
    for h, ps in secs:
        out.append(f"## {h}")
        out.append("\n\n".join(ps))
        out.append("")
    text = "\n".join(out).rstrip() + "\n"
    text = re.sub(r"\n{3,}", "\n\n", text)
    open(a.out, "w", encoding="utf-8").write(text)

    got = set(words(text))
    missing = [w for w in src_words if w not in got]
    n_src = len(src_words)
    body = sum(len(p) for _, ps in secs for p in ps)
    drops = {}
    for what, t in doc.dropped:
        drops[what] = drops.get(what, 0) + 1
    print(f"wrote {a.out}: {len(secs)} sections, {body} chars; dropped {drops}")
    if missing:
        print(f"  WARNING words lost: {len(missing)}/{n_src}: {' '.join(missing[:40])}", file=sys.stderr)


if __name__ == "__main__":
    main()
