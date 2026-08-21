#!/usr/bin/env python3
"""Convert a Markdown file into Confluence Cloud HTML.

The Atlassian MCP `createConfluencePage` / `updateConfluencePage` tools accept
`contentFormat: "html"`, which Confluence converts to ADF. Their own
`contentFormat: "markdown"` path mangles several constructs this repository
relies on, so we parse the Markdown here and emit the HTML ourselves.

Constructs handled explicitly, each one verified against a live Confluence
Cloud page:

- `<br>` inside a table cell becomes a second paragraph in that cell. The
  markdown path drops the tag and leaves a bare newline, which ADF renders as
  a space, running the lines together.
- HTML comments are removed. The markdown path leaks `<!--` and `-->` as
  literal text and renders any image inside the comment.
- Soft line breaks are resolved the CommonMark way instead of becoming forced
  line breaks: a break between two CJK characters joins with nothing, and any
  other break joins with a space.
- Images become a visible placeholder panel naming the file to paste, because
  a relative path cannot resolve on Confluence and the MCP has no attachment
  upload tool. The report lists every figure so they can be pasted by hand.
- Task lists become native Confluence task items with their checked state.
- Fenced code blocks keep their language tag.

Usage:
    md2confluence.py INPUT.md -o OUTPUT.html
    md2confluence.py INPUT.md --json -o OUTPUT.json
"""

from __future__ import annotations

import argparse
import html
import json
import re
import sys
import unicodedata
from pathlib import Path

try:
    from markdown_it import MarkdownIt
    from markdown_it.renderer import RendererHTML
    from mdit_py_plugins.tasklists import tasklists_plugin
except ImportError:  # pragma: no cover - dependency guidance
    sys.exit(
        "missing dependencies. install them with:\n"
        "    python3 -m pip install --user markdown-it-py mdit-py-plugins linkify-it-py"
    )

IMG_SENTINEL = "\x00IMG:%d\x00"
IMG_PATTERN = re.compile(r"\x00IMG:(\d+)\x00")
# The attribute group must start with whitespace so that `<thead>` is not read
# as a `<th>` carrying an `ead` attribute.
CELL_PATTERN = re.compile(r"<(td|th)((?:\s[^>]*)?)>(.*?)</\1>", re.DOTALL)
BR_PATTERN = re.compile(r"<br\s*/?>", re.IGNORECASE)
COMMENT_PATTERN = re.compile(r"<!--.*?-->", re.DOTALL)


def is_cjk(char: str) -> bool:
    """Report whether a character is one that CJK text sets without spaces."""
    if not char:
        return False
    code = ord(char)
    return (
        0x3000 <= code <= 0x30FF  # CJK punctuation, hiragana, katakana
        or 0x3400 <= code <= 0x4DBF  # CJK extension A
        or 0x4E00 <= code <= 0x9FFF  # CJK unified ideographs
        or 0xFF00 <= code <= 0xFFEF  # halfwidth and fullwidth forms
        or unicodedata.category(char) == "Lo" and code > 0x2E80
    )


def strip_html_comments(text: str) -> tuple[str, int]:
    """Remove HTML comments, leaving fenced code blocks untouched."""
    blocks: list[str] = []

    def stash(match: re.Match[str]) -> str:
        blocks.append(match.group(0))
        return "\x00FENCE:%d\x00" % (len(blocks) - 1)

    protected = re.sub(r"^(`{3,}|~{3,}).*?^\1[^\n]*$", stash, text,
                       flags=re.DOTALL | re.MULTILINE)
    stripped, count = COMMENT_PATTERN.subn("", protected)
    restored = re.sub(r"\x00FENCE:(\d+)\x00", lambda m: blocks[int(m.group(1))],
                      stripped)
    # Collapse blank lines a removed comment left behind.
    restored = re.sub(r"\n{3,}", "\n\n", restored)
    return restored, count


class ConfluenceRenderer(RendererHTML):
    """Render markdown-it tokens as the HTML subset Confluence accepts."""

    def __init__(self, parser=None):
        super().__init__(parser)
        self.images: list[dict[str, str]] = []
        self.unresolved_links: list[str] = []

    def link_open(self, tokens, idx, options, env):
        href = tokens[idx].attrGet("href") or ""
        # A link with no scheme points at a sibling file or an in-page anchor.
        # Neither survives the move to Confluence, where the target lives at a
        # different URL and headings get their own anchor ids.
        if href and "://" not in href and not href.startswith("mailto:"):
            self.unresolved_links.append(href)
        return self.renderToken(tokens, idx, options, env)

    def image(self, tokens, idx, options, env):
        token = tokens[idx]
        src = token.attrGet("src") or ""
        alt = self.renderInlineAsText(token.children, options, env)
        self.images.append({"path": src, "alt": alt})
        return IMG_SENTINEL % (len(self.images) - 1)

    def softbreak(self, tokens, idx, options, env):
        before = ""
        after = ""
        for prev in reversed(tokens[:idx]):
            if prev.content:
                before = prev.content[-1]
                break
        for nxt in tokens[idx + 1:]:
            if nxt.content:
                after = nxt.content[0]
                break
        if is_cjk(before) or is_cjk(after):
            return ""
        return " "

    def fence(self, tokens, idx, options, env):
        token = tokens[idx]
        language = token.info.strip().split()[0] if token.info.strip() else ""
        body = html.escape(token.content, quote=False)
        if language:
            return '<pre><code class="language-%s">%s</code></pre>' % (
                html.escape(language, quote=True), body)
        return "<pre><code>%s</code></pre>" % body

    def code_block(self, tokens, idx, options, env):
        return "<pre><code>%s</code></pre>" % html.escape(
            tokens[idx].content, quote=False)

    def html_block(self, tokens, idx, options, env):
        # Raw HTML blocks do not survive the ADF conversion predictably. The
        # only ones this repository uses are comments, already stripped.
        return ""

    def bullet_list_open(self, tokens, idx, options, env):
        if "contains-task-list" in (tokens[idx].attrGet("class") or ""):
            return '<ul data-type="task-list">'
        return "<ul>"

    def list_item_open(self, tokens, idx, options, env):
        classes = tokens[idx].attrGet("class") or ""
        if "task-list-item" in classes:
            return '<li data-type="task-item">'
        return "<li>"


def build_parser() -> MarkdownIt:
    md = MarkdownIt("gfm-like", {"html": True, "linkify": True})
    md.use(tasklists_plugin, enabled=True)
    return md


def normalize_task_items(body: str) -> str:
    """Give task items the checkbox and inline-only body that ADF requires."""
    def fix(match: re.Match[str]) -> str:
        inner = match.group(1)
        # The tasklists plugin emits its own checkbox; rewrite it to the
        # attribute shape Confluence expects.
        checkbox = re.search(r'<input[^>]*class="task-list-item-checkbox"[^>]*>',
                             inner)
        checked = bool(checkbox and "checked" in checkbox.group(0))
        inner = re.sub(r'<input[^>]*class="task-list-item-checkbox"[^>]*>\s*', "",
                       inner)
        # Task items are inline-only, so the paragraph wrapper has to go.
        inner = re.sub(r"</p>\s*<p>", " ", inner, flags=re.DOTALL)
        inner = re.sub(r"^\s*<p>(.*)</p>\s*$", r"\1", inner, flags=re.DOTALL)
        box = '<input type="checkbox" checked>' if checked \
            else '<input type="checkbox">'
        return '<li data-type="task-item">%s %s</li>' % (box, inner.strip())

    return re.sub(r'<li data-type="task-item">(.*?)</li>', fix, body,
                  flags=re.DOTALL)


def split_cell_paragraphs(body: str) -> tuple[str, int]:
    """Turn `<br>` inside table cells into separate paragraphs."""
    count = 0

    def fix(match: re.Match[str]) -> str:
        nonlocal count
        tag, attrs, inner = match.group(1), match.group(2), match.group(3)
        parts = [p.strip() for p in BR_PATTERN.split(inner)]
        parts = [p for p in parts if p]
        if len(parts) > 1:
            count += 1
        if not parts:
            return "<%s%s><p></p></%s>" % (tag, attrs, tag)
        paragraphs = "".join("<p>%s</p>" % p for p in parts)
        return "<%s%s>%s</%s>" % (tag, attrs, paragraphs, tag)

    return CELL_PATTERN.sub(fix, body), count


def apply_image_placeholders(body: str, images: list[dict[str, str]]) -> str:
    """Replace image sentinels with a panel naming the figure to paste."""
    def panel(match: re.Match[str]) -> str:
        item = images[int(match.group(1))]
        label = html.escape(item["alt"] or Path(item["path"]).stem, quote=False)
        path = html.escape(item["path"], quote=False)
        return (
            '<div data-type="panel-info"><p>Figure to paste manually: '
            "<code>%s</code> (%s)</p></div>" % (path, label)
        )

    body = re.sub(r"<p>\s*\x00IMG:(\d+)\x00\s*</p>", panel, body)

    def inline(match: re.Match[str]) -> str:
        item = images[int(match.group(1))]
        return "<em>[figure: %s]</em>" % html.escape(item["path"], quote=False)

    return IMG_PATTERN.sub(inline, body)


def extract_title(tokens) -> tuple[str | None, int]:
    """Return the leading level-1 heading and the token count to drop."""
    for idx, token in enumerate(tokens):
        if token.type == "heading_open" and token.tag == "h1":
            if idx != 0:
                return None, 0
            inline = tokens[idx + 1]
            return inline.content.strip(), 3
        if token.type not in ("front_matter",):
            return None, 0
    return None, 0


def convert(source: str, keep_h1: bool = False) -> dict:
    warnings: list[str] = []
    source, comments_removed = strip_html_comments(source)
    if comments_removed:
        warnings.append("removed %d HTML comment(s)" % comments_removed)

    md = build_parser()
    renderer = ConfluenceRenderer(md)
    md.renderer = renderer

    tokens = md.parse(source)
    title, drop = extract_title(tokens)
    if title and not keep_h1:
        tokens = tokens[drop:]
    elif title:
        title = None

    body = md.renderer.render(tokens, md.options, {})
    body = normalize_task_items(body)
    body, split_cells = split_cell_paragraphs(body)
    if split_cells:
        warnings.append("split %d table cell(s) on <br> into paragraphs" % split_cells)
    body = apply_image_placeholders(body, renderer.images)
    body = re.sub(r"\n+", "", body).strip()

    return {
        "title": title,
        "body": body,
        "images": renderer.images,
        "unresolved_links": renderer.unresolved_links,
        "warnings": warnings,
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Convert Markdown to Confluence Cloud HTML.")
    parser.add_argument("input", type=Path, help="Markdown file to convert")
    parser.add_argument("-o", "--out", type=Path,
                        help="write the result here instead of stdout")
    parser.add_argument("--json", action="store_true",
                        help="emit a JSON object with title, body, and images")
    parser.add_argument("--keep-h1", action="store_true",
                        help="keep the leading H1 in the body instead of "
                             "treating it as the page title")
    args = parser.parse_args()

    source = args.input.read_text(encoding="utf-8")
    result = convert(source, keep_h1=args.keep_h1)

    payload = json.dumps(result, ensure_ascii=False, indent=2) if args.json \
        else result["body"]
    if args.out:
        args.out.write_text(payload + "\n", encoding="utf-8")
    else:
        print(payload)

    report = ["source: %s" % args.input]
    report.append("title: %s" % (result["title"] or "(none; body has no leading H1)"))
    report.append("body: %d characters" % len(result["body"]))
    if args.out:
        report.append("written to: %s" % args.out)
    for warning in result["warnings"]:
        report.append("note: %s" % warning)
    if result["images"]:
        report.append("figures to paste manually (%d):" % len(result["images"]))
        base = args.input.parent
        for item in result["images"]:
            local = base / item["path"]
            state = "found" if local.is_file() else "MISSING"
            report.append("  %s  [%s]  %s" % (local, state, item["alt"]))
    else:
        report.append("figures to paste manually: none")
    if result["unresolved_links"]:
        report.append("links that will not resolve on Confluence (%d):"
                      % len(result["unresolved_links"]))
        for href in result["unresolved_links"]:
            report.append("  %s" % href)
    print("\n".join(report), file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
