# Confluence Cloud rendering notes

Verified on 2026-08-20 and 2026-08-21 against `tier4.atlassian.net` by
publishing test pages through the Atlassian MCP and reading the stored
storage-format body back. These are the reasons `md2confluence.py` exists.

## Why not contentFormat: "markdown"

`createConfluencePage` accepts `contentFormat: "markdown"` and converts the
source itself. That converter damages the following.

| Construct | What the markdown path does | Consequence |
|---|---|---|
| `<br>` inside a table cell | Drops the tag, leaves a bare newline in the ADF text node | The lines run together, because ADF renders a newline inside a paragraph as a space |
| HTML comment | Passes `<!--` and `-->` through as literal text | The markers appear in the page, and an image inside the comment renders as a broken image |
| Soft line break inside a paragraph | Emits a hard `<br />` | A hard-wrapped paragraph keeps its source line breaks, and a wrapped CJK paragraph breaks mid-sentence |
| An escaped pipe inside a code span in a table cell | Keeps the backslash | The backslash shows up in the rendered cell instead of being consumed as an escape |
| Bare URL ending in a period | Pulls the period into the href | The link is broken |

## What the markdown path gets right

Worth knowing, because it means the HTML converter only has to preserve these
rather than work around them: pipe tables including header rows and empty
cells, fenced code blocks with and without a language tag, nested bullet and
numbered lists, task lists with their checked state, block quotes, horizontal
rules, inline code, italic, strikethrough, explicit links, reference-style
links, and bare URLs followed by whitespace.

## Confirmed HTML mappings

Sent as `contentFormat: "html"`, these land as intended.

| Input HTML | Stored as |
|---|---|
| `<td><p>a</p><p>b</p></td>` | A table cell holding two paragraphs |
| `<ul data-type="task-list"><li data-type="task-item"><input type="checkbox" checked> x</li></ul>` | `ac:task-list` with `ac:task-status` set to `complete` |
| `<div data-type="panel-info"><p>x</p></div>` | The `info` macro |
| `<pre><code class="language-c">...</code></pre>` | The `code` macro with its language parameter |
| `<s>x</s>` | `<del>x</del>` |
| `<td><p></p></td>` | An empty cell |

## Constraints worth remembering

- Task item bodies are inline only. A paragraph wrapper inside
  `<li data-type="task-item">` has to be removed.
- Table cells cannot hold a nested table or a normal expand.
- Panels cannot hold tables, expands, block quotes, or other panels.
- `<thead>` is accepted, and Confluence stores the header row inside `tbody`
  with `<th>` cells.
- Images cannot be uploaded through the MCP; there is no attachment tool. A
  relative `src` becomes an `ri:url` resource, which Confluence resolves as an
  absolute external URL and therefore fails to load.
