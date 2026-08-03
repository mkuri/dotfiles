# Vendor skill source registry

Tracks every externally sourced skill under `agents/skills/vendor/`. The pin
(upstream repo, path, ref, tree SHA) lives in each skill's `SKILL.md`
frontmatter; this registry adds the license and review state required to
redistribute the copies from this public repository.

See [`manage-vendor-skills`](../mkuri/manage-vendor-skills/SKILL.md) for the
install, license, and update workflow.

| Skill | Upstream | License | Pinned tree SHA | LICENSE vendored | Execution surface | Reviewed | Reviewer |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `grilling` | [mattpocock/skills](https://github.com/mattpocock/skills) `skills/productivity/grilling` @ `v1.1.0` | MIT | `0ace40ac10f5c0b1534324e4e109ebfa831fb361` | Yes | None (instruction-only) | 2026-08-03 | mkuri |

## Notes

### grilling

- Instruction-only skill; no bundled scripts, MCP config, hooks, or
  `allowed-tools` to review.
- MIT license copied to `vendor/grilling/LICENSE` (upstream copyright:
  2026 Matt Pocock) to satisfy public redistribution.
- No product-policy override applies.
