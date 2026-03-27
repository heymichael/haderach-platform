---
id: "70"
title: "Consider rapidfuzz for vendor resolution"
status: pending
group: agent
phase: strategy
priority: low
type: enhancement
tags: [agent, mcp, resolver, fuzzy-matching, strategy]
dependencies: ["68"]
effort: small
created: 2026-03-27
---

## Conversation transcript

The following is a direct transcript of a conversation about whether to adopt `rapidfuzz` for vendor name resolution in the MCP analytics server.

---

**Q: Which package did we end up using for the fuzzy match?**

We didn't use a package — the fuzzy matching is hand-rolled in `mcp_server/resolver.py`. The resolution pipeline is:

1. **Exact document ID** — direct Firestore lookup
2. **Exact name** — case-insensitive string comparison
3. **Alias match** — checks the `aliases` array field on vendor docs
4. **Normalised match** — strips punctuation, collapses whitespace, then compares (e.g. "O'Brien & Associates, LLC" → "obrien associates llc")
5. **Token match** — checks if all query tokens appear in the vendor name (e.g. "jennifer" matches "Jennifer Chen-Manwell")

It's simple string operations — `re.sub`, `.lower()`, `.split()`, `all(t in name for t in tokens)`. No external library like `fuzzywuzzy` or `rapidfuzz`.

This works well for the current vendor set because the resolution is backed by aliases for the tricky cases (e.g. "AWS" → "Amazon Web Services"). If you eventually hit a point where token matching produces too many false positives or misses, that's when you'd swap step 5 for something like `rapidfuzz` with a similarity threshold. But for now the simpler approach is easier to reason about and test.

---

**Q: What does rapidfuzz do that we aren't?**

The main difference is **edit distance** — how many character-level changes it takes to turn one string into another.

Our token match asks: "are all my search words present somewhere in the vendor name?" That's a containment check. It works great for partial names ("jennifer" → "Jennifer Chen-Manwell") but it has two blind spots:

1. **Typos** — "Jennfer" won't match "Jennifer" because the token isn't present. `rapidfuzz` would score that at ~93% similarity and still match.

2. **Reordering without containment** — "Manwell Chen" would match (both tokens are present), but "Chen-Man" wouldn't (the token "chen-man" isn't in "jennifer chen-manwell" as a substring). `rapidfuzz` handles partial and reordered matches with scored confidence.

3. **Graduated confidence** — our approach is binary (match or no match), so "Acme" matching 12 vendors all come back as equally ambiguous. `rapidfuzz` gives each a score (e.g. "Acme Corp" = 90%, "Acme Logistics" = 85%), so you could auto-pick the top one above a threshold or rank the ambiguous candidates.

In practice, the gap matters most when users are typing quickly and making spelling mistakes. Right now the alias table covers the common shortcuts ("AWS", "Rhonda"), and the LLM tends to clean up obvious typos before passing them to the tool. If you start seeing `not_found` results for vendors that should have matched, that's the signal to swap in `rapidfuzz` at step 5.

---

**Q: Performance wise, is RapidFuzz slower than what we have now?**

No, `rapidfuzz` would actually be extremely fast — it's written in C++ with Python bindings, so the core distance calculations run at native speed. For your vendor set (a few hundred vendors), the difference is negligible either way. Both approaches would complete in under a millisecond.

Where performance would matter is at scale — thousands or tens of thousands of items. And even there, `rapidfuzz` has optimizations like early termination (stop calculating once the score drops below your threshold) that keep it fast.

Your current approach is essentially free though — it's just Python string `in` checks against a list. There's no real performance reason to avoid `rapidfuzz`; the reason we didn't use it is simplicity. One less dependency, easier to understand and test, and the alias table handles the cases where simple containment falls short. It's a "you ain't gonna need it" call, not a performance call.

---

## Decision

Deferred. Revisit if `not_found` results start appearing for vendors that should have matched. The trigger to adopt `rapidfuzz` is user-facing resolution failures that aliases can't practically cover.
