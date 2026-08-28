# Third-Party Notices

## grill-me / grill-with-docs (Matt Pocock)

The relentless-interview discipline used in tandem's Understand phase (frontier-batched questioning — every question whose prerequisites are settled, asked
together with a recommended answer each, evolved from the original one-at-a-time form; and
"if the codebase can answer it, explore the codebase instead"), and the three-part ADR test used at the Plan gate, are adapted from the
**grill-me** and **grill-with-docs** skills by **Matt Pocock**
(https://github.com/mattpocock/skills), used under the MIT License:

```
MIT License

Copyright (c) 2026 Matt Pocock

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## subagent-driven-development (Jesse Vincent, superpowers)

The adaptive subagent execution protocol in tandem's build playbook — zero-context task
briefs, fresh per-task implementer subagents returning short statuses with detailed reports
on disk, and risk-sized task review gates — is adapted from the **subagent-driven-development**
skill in **Jesse Vincent's** `superpowers` project
(https://github.com/obra/superpowers, MIT License, Copyright (c) 2025 Jesse Vincent).
Tandem adapts the ideas rather than copying the skill: it keeps its own single ledger
(`state.md`), its own review gate (`tandem-review`), and adaptive rather than uniform
ceremony.

## grill-me-codex / grill-with-docs-codex / claudex-loop (Chase AI)

The Codex CLI critic mechanics that tandem's `references/codex-protocol.md` hardens and
extends — forcing read-only on `codex exec resume` via `-c sandbox_mode`, the non-TTY stdin
EOF hang avoidance, thread-id capture and explicit-id resume (never `--last`), the 10-minute
ceiling, the don't-pin-`-m` rule and model echo, and the bounded Claude-as-arbiter review loop
with logged rejections and honest deadlock — were first worked out in **Chase AI's**
`grill-me-codex` and `grill-with-docs-codex` skills, now published as **claudex-loop**
(https://github.com/chaseai-yt/claudex-loop), used under the MIT License (Copyright (c) 2026
Chase AI). Those skills' interview act is in turn adapted from Matt Pocock's `grill-me` /
`grill-with-docs` (above). Tandem is a from-scratch redesign of the lifecycle around those
mechanics, not a fork.

```
MIT License

Copyright (c) 2026 Chase AI

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
