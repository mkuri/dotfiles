---
name: japanese-web-typography
description: Base CSS for web pages whose text is Japanese, so that spacing between Japanese and Latin text, punctuation, and line breaking look right without typing spaces. Use when creating or restyling a web page, template, Tailwind base layer, or reset stylesheet that shows Japanese text.
---

# Japanese web typography

Browsers do not space Japanese and Latin text or trim punctuation by default.
Set it in CSS so that the source text follows the writing rule "no space
between Japanese and English words, numbers, or code" and the page still reads
well.

Facts below were checked on 2026-11-27 against MDN browser-compat-data 8.1.11
and CSS Text Level 4 (W3C Working Draft, 2026-08-14).

## Base CSS

Put this in the reset or base layer. `:where()` keeps specificity at zero, so
component styles override it without `!important`.

```css
:where(:root) {
  text-autospace: normal;
  text-spacing-trim: trim-start;
  line-break: strict;
  overflow-wrap: anywhere;
}

:where(pre, code, kbd, samp) {
  text-autospace: no-autospace;
  text-spacing-trim: space-all;
}

:where(time) {
  text-autospace: no-autospace;
}

:where(
  input:not([type="button" i], [type="submit" i], [type="reset" i]),
  textarea,
  [contenteditable]
) {
  text-autospace: no-autospace;
}

:where(h1, h2, h3, h4, h5, h6) {
  text-wrap: balance;
  word-break: auto-phrase;
}
```

Set `<html lang="ja">`. `word-break: auto-phrase` does nothing without a
Japanese (or Korean) content language.

## What each rule does and where it works

| Rule | Effect | Support |
|---|---|---|
| `text-autospace: normal` | Inserts a 1/8 ideographic gap between kana or kanji and directly adjoining Latin letters or digits. Not around punctuation, so half-width parentheses get no gap. The browser initial value is `no-autospace`, so set it explicitly. | Chrome and Edge 140, Firefox 145, Safari 18.4. Baseline since 2025-11. |
| `text-spacing-trim: trim-start` | Sets an opening full-width bracket at a line start half-width, and collapses space between adjacent punctuation. | Chrome and Edge 123 only. Ignored elsewhere. |
| `line-break: strict` | Keeps small kana and `ー` from starting a line. | Widely available. |
| `overflow-wrap: anywhere` | Breaks long URLs or identifiers instead of overflowing, and counts those breaks for min-content, which helps flex and grid children. Use it instead of `word-break: break-all`, which also turns off Japanese line-breaking rules. | Widely available. |
| `text-wrap: balance` | Evens out line lengths in short headings. | Widely available since 2026-11. |
| `word-break: auto-phrase` | Breaks Japanese headings at phrase boundaries. Headings and table cells only; it makes body text ragged. | Chrome and Edge 119 only. |

Unsupported properties are ignored, so the whole block is safe as progressive
enhancement.

## Exclusions

- Code (`pre`, `code`, `kbd`, `samp`): spacing would shift monospaced columns.
- `time`: dates such as `2026年11月27日` are written without gaps.
- Text inputs and `contenteditable`: inserted gaps make caret movement
  unstable.

## Tailwind CSS v4

Put the base CSS in the CSS entry file after `@import "tailwindcss";`, inside
`@layer base { ... }`. Tailwind ships `text-balance`, `text-pretty`, and
`wrap-anywhere` utilities, but none for `text-autospace`, `text-spacing-trim`,
`line-break`, or `word-break: auto-phrase`; use the base layer or arbitrary
properties such as `[text-autospace:normal]`.

## Avoid

- Typing half-width spaces between Japanese and Latin text to fake the gap.
- `font-feature-settings: "palt"` on body text; it over-tightens kana. Use it
  only on headings or captions, if at all.
- `text-wrap: pretty` as a requirement: Firefox does not support it.

## Sources

- https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/text-autospace
- https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/text-spacing-trim
- https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/word-break
- https://www.w3.org/TR/css-text-4/
- https://tailwindcss.com/docs/adding-custom-styles
