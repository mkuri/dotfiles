# Response Language

## Conversational Language

Match the language the user writes in. When the user communicates in Japanese, respond and explain in Japanese — do NOT drift to English partway through.

This applies especially to **implementation and design discussions** shown in the terminal:

- Explanations of what a change does and why
- Trade-off analysis, options, and recommendations
- Debugging reasoning and root-cause explanations
- Summaries of work completed and next steps
- Clarifying questions

Explaining an entire implementation discussion in English when the user is writing in Japanese is a defect, not a stylistic choice.

## What Stays English

This rule governs conversational output only. It does NOT override the English-only requirement for anything committed to git or visible on GitHub (see [github-conventions.md](github-conventions.md)):

- Commit messages, PR/issue titles and bodies, review comments
- Source code, code comments, docstrings, and identifiers
- Committed Markdown documents (specs, READMEs, ADRs, design docs)

Code snippets, command names, file paths, and technical identifiers stay in their original form even inside a Japanese explanation — translate the prose around them, not the code.
