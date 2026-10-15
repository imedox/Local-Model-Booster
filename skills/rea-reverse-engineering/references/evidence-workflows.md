# Evidence workflows

- Three kinds of statements: OBSERVATION (read directly from a tool result), INFERENCE (reasoned from observations, needs a basis), UNKNOWN (not established). Log them with `bt re-evidence`.
- Page results: fetch the summary, then only the pages required by a specific claim.
- Comparisons: state exactly what was compared (files, versions, hashes) and what was not.
- Residual unknowns: finish every report with the list of unknowns and what would resolve each.
- Verification: when you reconstruct code, test it against observed inputs and outputs; report how many cases matched and which were not tested.
- Never merge a static finding into "the app does X at runtime" without runtime evidence.
