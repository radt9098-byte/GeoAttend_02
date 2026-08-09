# Agent Instructions

You operate within a 3-layer architecture that separates responsibilities to
maximize reliability. LLMs are probabilistic, while most business logic is
deterministic and requires consistency. This system solves that problem.

## 3-Layer Architecture

### Layer 1: Directive (What to do)
- Essentially SOPs written in Markdown, living in `directives/`
- They define objectives, inputs, tools/scripts to use, outputs, and edge
  cases
- Natural-language instructions, like you'd give to a mid-level employee
- Written once by the human (or refined with the agent's help), then reused
  every time — you don't re-explain the task from scratch each session

### Layer 2: Orchestration (Decisions)
- Your job: intelligent routing.
- Read the directives, call execution tools in the right order, handle
  errors, ask clarifying questions, update directives with what you learn
- You are the glue between intent and execution
  - Example: you don't build the Flutter screen yourself from memory — you
    read `directives/build_screen.md`, define inputs/outputs, then run
    `execution/scaffold_screen.py`
- Never skip straight to freehand code generation when a directive and
  script already exist for the task — deterministic beats improvised

### Layer 3: Execution (Doing the work)
- Deterministic, testable scripts/configs in `execution/`
- Secrets (Firebase keys, EmailJS keys, API tokens) stored in `.env`, never
  hardcoded into a directive or committed to git
- Scripts handle: scaffolding new screens, running `flutter build apk`,
  updating Firestore rules, generating release notes
- Reliable, testable, fast — a script either works or throws a clear error,
  it doesn't "sort of" work
- Well-commented, so a non-coder reviewing the diff can still follow along

**Why it works:**
If you do everything yourself, errors compound. 90% accuracy per step =
~59% success over 5 steps. The solution is to push complexity into
deterministic code so you focus only on decision-making.

---

## How this applies to GeoAttend specifically

```
geoattend/
├── directives/
│   ├── add_new_screen.md        # SOP: how to scaffold a screen matching
│   │                             # the existing theme, navigation pattern,
│   │                             # and error-handling style
│   ├── firestore_schema_change.md  # SOP: how to add/modify a Firestore
│   │                                 # field without breaking existing data
│   ├── release_new_version.md   # SOP: version bump, changelog, APK build,
│   │                             # what to test before calling it done
│   └── fix_reported_bug.md      # SOP: reproduce, isolate, fix, verify —
│                                  # in that order, no shortcuts
├── execution/
│   ├── scaffold_screen.py       # Generates a new screen file from a
│   │                             # template matching main.dart's theme
│   ├── build_apk.sh             # Runs flutter build, checks for common
│   │                             # errors, reports pass/fail clearly
│   └── validate_firestore_rules.py
├── .env                          # EmailJS keys, any future secrets
└── AGENT_FRAMEWORK.md            # This file
```

### Example directive: `directives/add_new_screen.md`

```markdown
# SOP: Add a New Screen

## Objective
Add a new screen to GeoAttend that matches the existing app's theme,
navigation, and error-handling conventions — not a one-off style.

## Inputs
- Screen name and purpose (from the human)
- Which existing screen it's most similar to (for pattern-matching)

## Steps
1. Run `execution/scaffold_screen.py <screen_name>` to generate the file
   skeleton with the correct theme imports already wired in.
2. Fill in the screen's specific fields/logic.
3. Add navigation entry point (button, menu item, or route).
4. Confirm it follows the "no dead-end back button" rule: logging in or
   completing an action should clear the back stack, per the bug fixed
   in v2.

## Edge Cases
- If the screen needs Firestore data, check `firestore_schema_change.md`
  first — don't invent new fields ad hoc.
- If the screen needs a new package, flag it to the human before adding —
  new dependencies mean a new potential build error.

## Output
A working screen file, plus a one-line summary of what was added and why,
so the human can review without reading the whole diff.
```

### Why this matters for your situation specifically
You've mentioned wanting zero errors and being burned by AI coding tools
before. The pattern behind that is almost always: the agent skipped
straight to "just write the code" without a repeatable process, so every
session reinvents the approach and reintroduces the same class of mistake.
Directives fix that — once a mistake is caught and fixed, it goes into the
directive so it can't quietly happen again next time.
