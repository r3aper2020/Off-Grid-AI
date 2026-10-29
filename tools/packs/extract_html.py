#!/usr/bin/env python3
"""Extract a web page's main text into a pack document (Markdown).

Copies text verbatim; only structure changes: <h2> headings become `## `
sections, and so do <h3> sub-headings (as "H2: H3", keeping citations small
and precise); <h4> become bold lines, list items become `- ` lines.
Every run of text inside <main> is kept, grouped by its nearest block
element, so text in <div>s (callouts, div-based tables) is not lost.
Navigation, images, figures, scripts, forms and page chrome are dropped.

A coverage check compares the words inside <main> with the words written
and reports any that went missing, so extraction gaps can't slip through
silently on safety-critical text.

Usage:
    python3 tools/packs/extract_html.py <url-or-file> -o out.md \\
        [--source-url URL] [--title TITLE] [--skip "Heading" ...]

Stdlib only. Fetching a URL is a plain GET; for sites that refuse
automated requests, save the page from a browser and pass the file.
"""

import argparse
import html
import re
import sys
import urllib.request
from html.parser import HTMLParser

DROP = {
    "script", "style", "noscript", "nav", "aside", "footer", "header",
    "figure", "svg", "button", "form", "iframe", "video", "picture",
    "template", "select",
}
VOID = {"br", "img", "hr", "input", "meta", "link", "source", "wbr", "area",
        "col", "embed", "track", "param"}
INLINE = {"a", "span", "strong", "b", "em", "i", "sup", "sub", "small",
          "abbr", "code", "u", "mark", "time", "cite", "q", "label", "font"}
# Elements whose id/class contains one of these are page chrome.
DROP_MARKERS = (
    "translation", "breadcrumb", "share", "social", "language-",
    "page-feedback", "last-reviewed", "sidebar", "toc", "fema-link",
    "usa-button", "visually-hidden", "sr-only", "element-invisible",
    # Project Gutenberg: license header/footer (trademark terms require
    # removing them when redistributing) and page-number anchors
    "pg-header", "pg-footer", "pg-machine-header", "pagenum", "pg-boilerplate",
    # MediaWiki (Wikibooks): edit links, nav boxes, footnote markers, images
    "mw-editsection", "navbox", "noprint", "reference", "mw-references",
    "thumb", "gallery", "mw-empty-elt", "metadata", "ambox", "printfooter",
)
# Whole paragraphs that are page furniture, not guidance.
CHROME_LINES = [re.compile(p, re.I) for p in (
    r"^(jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)[a-z]*\.? \d{1,2}, \d{4}$",
    r"^(español|for everyone|about this page|content source:?|"
    r"download infographic)$",
    r"^(published|updated|reviewed|last updated):? .*\d{4}$",
    r"^sources and page info",
    r"^this page was last updated on this date",
    r"^the information on this page was last reviewed",
    r"^view all",
    # CDC media/link furniture
    r"^(download|view|view larger|downloadview larger|low resolution video|"
    r"audio - (male|female)|report it now)$",
    r"^keep reading:?",
    r"^(format|language|length):",
    r"^sources?printshare$",
)]
# Sections that link out or aren't guidance.
DEFAULT_SKIP = {
    "additional resources", "related resources", "related content",
    "related pages", "related links", "resources", "associated content",
    "on this page", "sources", "references", "more information",
}


class MainText(HTMLParser):
    def __init__(self, container="main"):
        super().__init__(convert_charrefs=True)
        self.container = container
        self.stack = []           # [(tag, element_id)]
        self.next_id = 0
        self.in_main = 0
        self.drop_tag = None
        self.drop_depth = 0
        self.blocks = []          # (kind, text)
        self.block_id = None
        self.kind = "p"
        self.buf = []
        self.all_text = []        # everything kept inside <main>, for coverage

    def _flush(self):
        text = re.sub(r"\s+", " ", "".join(self.buf)).strip()
        if text:
            self.blocks.append((self.kind, text))
        self.buf = []

    def handle_starttag(self, tag, attrs):
        if self.drop_tag:
            if tag == self.drop_tag:
                self.drop_depth += 1
            return
        if tag == self.container:
            self.in_main += 1
        if self.in_main:
            marks = " ".join(v or "" for k, v in attrs if k in ("id", "class"))
            if tag in DROP or any(m in marks.lower() for m in DROP_MARKERS):
                if tag not in VOID:
                    self.drop_tag, self.drop_depth = tag, 1
                return
        if tag in VOID:
            if tag == "br" and self.in_main:
                self.buf.append(" ")
            return
        if tag not in INLINE:
            self.all_text.append(" ")  # block boundaries separate words
        self.next_id += 1
        self.stack.append((tag, self.next_id))

    def handle_endtag(self, tag):
        if self.drop_tag:
            if tag == self.drop_tag:
                self.drop_depth -= 1
                if self.drop_depth == 0:
                    self.drop_tag = None
            return
        if tag in VOID:
            return
        if tag not in INLINE:
            self.all_text.append(" ")
        # Pop to the matching open tag (tolerates sloppy HTML).
        for i in range(len(self.stack) - 1, -1, -1):
            if self.stack[i][0] == tag:
                del self.stack[i:]
                break
        if tag == self.container and self.in_main:
            self._flush()
            self.in_main -= 1

    def handle_data(self, data):
        if not self.in_main or self.drop_tag:
            return
        if not data.strip():
            # Whitespace-only runs (e.g. <strong> </strong>) still separate
            # words; dropping them glues neighbours together.
            self.buf.append(" ")
            self.all_text.append(" ")
            return
        self.all_text.append(data)
        block = next(((t, i) for t, i in reversed(self.stack)
                      if t not in INLINE), ("p", 0))
        if block[1] != self.block_id:
            self._flush()
            self.block_id = block[1]
            tags = [t for t, _ in self.stack]
            if block[0] in ("h1", "h2", "h3", "h4"):
                self.kind = block[0]
            elif "li" in tags:
                self.kind = "li"
            else:
                self.kind = "p"
        self.buf.append(data)


def is_chrome(text):
    return any(p.search(text) for p in CHROME_LINES)


def to_markdown(blocks, title, source_url, skip):
    if title is None:
        title = next((t for k, t in blocks if k == "h1"), "Untitled")
    out = [f"# {title}", f"Source: {source_url}", ""]
    section, lines, skipping = "Overview", [], False
    h2 = None  # until an <h2> appears, <h3>s stand alone

    def flush():
        body = "\n\n".join(lines).strip()
        if body and not skipping:
            out.extend([f"## {section}", body, ""])

    for kind, text in blocks:
        if kind == "h1":
            continue
        if kind == "h2":
            flush()
            h2 = section = text
            lines = []
            skipping = text.strip().lower() in skip
        elif kind == "h3":
            flush()
            section, lines = (f"{h2}: {text}" if h2 else text), []
        elif kind == "h4":
            lines.append(f"**{text}**")
        elif kind == "li":
            if lines and lines[-1].startswith("- "):
                lines[-1] += f"\n- {text}"
            else:
                lines.append(f"- {text}")
        elif not is_chrome(text):
            lines.append(text)
    flush()
    return "\n".join(out).rstrip() + "\n"


def words(text):
    return set(re.findall(r"[a-z0-9½⅛¼¾]+", text.lower()))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("page")
    ap.add_argument("-o", "--out", required=True)
    ap.add_argument("--source-url")
    ap.add_argument("--title")
    ap.add_argument("--skip", nargs="*", default=[])
    ap.add_argument("--container", default="main",
                    help="element holding the content (e.g. body)")
    ap.add_argument("--drop-before", help="ignore text before this heading")
    ap.add_argument("--drop-after", help="ignore text from this heading on")
    args = ap.parse_args()

    if re.match(r"https?://", args.page):
        req = urllib.request.Request(args.page,
                                     headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=30) as r:
            raw = r.read().decode("utf-8", "replace")
        source = args.source_url or args.page
    else:
        raw = open(args.page, encoding="utf-8").read()
        if not args.source_url:
            sys.exit("--source-url is required for local files")
        source = args.source_url

    parser = MainText(args.container)
    parser.feed(raw)
    parser.close()
    if not parser.blocks:
        sys.exit("no <main> content found")

    # Coverage: every word inside <main> must reach the extracted blocks.
    extracted = " ".join(t for _, t in parser.blocks)
    missing = sorted(words("".join(parser.all_text)) - words(extracted))
    if missing:
        print(f"warning: words lost in extraction: {missing}", file=sys.stderr)

    blocks = parser.blocks
    if args.drop_before:
        i = next((i for i, (k, t) in enumerate(blocks)
                  if k.startswith("h") and t.lower().startswith(args.drop_before.lower())), None)
        if i is None:
            sys.exit(f"--drop-before heading not found: {args.drop_before}")
        blocks = blocks[i:]
    if args.drop_after:
        i = next((i for i, (k, t) in enumerate(blocks)
                  if k.startswith("h") and t.lower().startswith(args.drop_after.lower())), None)
        if i is not None:
            blocks = blocks[:i]
    parser.blocks = blocks
    skip = DEFAULT_SKIP | {s.lower() for s in args.skip}
    md = html.unescape(to_markdown(parser.blocks, args.title, source, skip))
    open(args.out, "w", encoding="utf-8").write(md)
    print(f"wrote {args.out} ({len(md)} chars)")


if __name__ == "__main__":
    main()
