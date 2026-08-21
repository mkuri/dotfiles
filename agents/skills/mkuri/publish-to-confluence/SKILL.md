---
name: publish-to-confluence
description: Publish repository Markdown documents to Confluence Cloud through the Atlassian MCP, converting them with md2confluence.py first. Use whenever the user asks to publish, upload, mirror, or update a Markdown file, design document, or set of documents on Confluence or the wiki, or asks how a document will render there.
---

# Publish Markdown to Confluence Cloud

Convert the Markdown with `scripts/md2confluence.py`, then create or update the
page with the Atlassian MCP tools using `contentFormat: "html"`. Do not paste
Markdown into `contentFormat: "markdown"`: that path silently damages several
constructs, listed in `references/rendering-notes.md`.

## Prerequisites

The converter needs three packages:

```bash
python3 -m pip install --user markdown-it-py mdit-py-plugins linkify-it-py
```

The Atlassian MCP connector must be connected. Confirm with
`getAccessibleAtlassianResources` and keep the returned `cloudId` for every
later call. If only `authenticate` and `complete_authentication` stubs are
available, the connector is not ready; report that and stop rather than
falling back to an API token.

## Workflow

1. Convert the document and read the report on stderr.

   ```bash
   python3 <skill>/scripts/md2confluence.py DOC.md -o /tmp/doc.html
   ```

   The report names the detected title, the figures to paste by hand, the
   links that will not resolve, and every transformation applied.

2. Check the detected title. The converter treats a leading level-1 heading as
   the page title and drops it from the body, because Confluence shows the
   title separately. When that heading is a section name rather than a
   document title, such as `# 概要` or `# Overview`, rerun with `--keep-h1`
   and choose a title yourself.

3. Confirm the destination with the user before any write. Ask for the space
   and, when the document belongs under an existing page, the parent page id.
   Never create a page in a space the user has not named. `getConfluenceSpaces`
   lists spaces; the site has hundreds, so filter with `keys` rather than
   paging through all of them.

4. Create or update the page.

   - New page: `createConfluencePage` with `cloudId`, `spaceId`, `title`,
     `contentFormat: "html"`, `body`, and `parentId` when nesting.
   - Existing page: `getConfluencePage` for its current `version.number`, then
     `updateConfluencePage` with the next version number. Republishing a
     document always updates its existing page; do not create a second page
     for the same source file.

5. Report the page URL and the list of figures still to be pasted.

## Figures

The MCP has no attachment upload tool, and a relative image path cannot
resolve on Confluence, so figures are pasted by hand. The converter puts an
info panel at each image position naming the file, so the place to drop each
one is visible on the page.

Build the PNG before publishing when only the `.puml` exists:

```bash
java -jar /tmp/plantuml.jar -charset UTF-8 FILE.puml
```

Tell the user which files to paste and where, using the paths from the
converter report. Leave the placeholder panels in place until the figures are
in; they are the marker for what is still missing.

## What still needs hands

The converter cannot fix these, and reports them instead:

- Links to sibling Markdown files, such as `29_reference_list.md`. Repoint
  them at the published Confluence page once that page exists.
- In-page anchor links, such as `#section-name`. Confluence assigns its own
  heading anchors.
- Figures, as described above.

## Language

Page bodies follow the source document. Do not translate a document as part of
publishing it unless the user asks.
