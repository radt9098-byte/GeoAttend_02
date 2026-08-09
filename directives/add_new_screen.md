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
