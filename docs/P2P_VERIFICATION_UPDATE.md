# P2P Verification Update

## Overview

The application now applies the same P2P/F2P verification flow to every normal player during add and update operations.

## Current Verification State

### Before
- Verification behavior differed across player categories.
- A `false_p2p_flagged` override list existed as a workaround for false positives.
- Verification relied on older fallback logic that was harder to reason about.

### Now
- All normal players use the same verification flow.
- The old `false_p2p_flagged` override list has been removed from application config.
- Current automatic verification is based on parser output, total level, and direct members-skill evidence.
- Activity-based boss/clue checks remain documented in the codebase, but they are temporarily disabled while hiscores activity parsing is hardened.

## Verification Flow

```text
Player add/update
    ↓
Special cases checked first:
  - fakes list        → always P2P
  - false_banned list → always F2P
    ↓
All other players
    ↓
Automatic verification checks:
  0. Parser detection (`potential_p2p > 0`)
  1. Total level exceeds the F2P maximum (1494)
  2. Members-only skills trained beyond base level
    ↓
Any check fails → P2P (`potential_p2p = 1`)
All checks pass → F2P (`potential_p2p = 0`)
```

## Key Methods

### `Player#check_p2p_stats(stats)`
- Main verification entry point for existing players.
- Handles special-case lists first.
- Uses detailed verification for all other players.

### `Player.detailed_p2p_verification(stats)`
- Evaluates parser output, total level, and trained members-only skills.
- Returns `true` when P2P evidence is found.

### `Player.initial_detailed_p2p_check(stats, name)`
- Applies the same core verification rules during player creation.

### `Player#check_p2p_hiscores_content`
- Retained for future activity-based verification work.
- Currently disabled in the automatic verification flow to avoid false positives from unstable activity parsing.

## Automatic Checks in Use

### Check 0: Parser Detection
- Uses parser-provided `potential_p2p` evidence.
- Catches obvious P2P accounts immediately.

### Check 1: Total Level
- F2P maximum total is 1494.
- Any total above 1494 means members-only skills have been trained.

### Check 2: Direct Members-Skill Evidence
- Looks for members-only skills above level 1 or with XP above 0.
- Avoids fragile arithmetic-only inference.

## Activity-Based Detection Status

Boss KC and clue-scroll evidence are **not** currently used in the automatic verification path.

That code and the associated rake tasks are still useful for manual investigation, but the automatic flow leaves them disabled until the hiscores activity parser is robust against upstream activity reordering.

## Impact

### New Players
- Verified during creation with the same core rules used for updates.

### Existing Players
- Re-verified on update using the same automatic checks.

### Special Lists
- `fakes` still force P2P.
- `false_banned` still force F2P.
- There is no longer a `false_p2p_flagged` override list to maintain.

## Benefits

1. Consistent verification rules for normal players.
2. Fewer manual overrides in application config.
3. Better resilience to skill-list changes such as Sailing.
4. Reduced false positives while activity parsing remains under review.

## Example Outcomes

### Legitimate F2P Player
- Base members-only skills only.
- Total level at or below 1494.
- Result: remains F2P.

### P2P Player With Trained Members Skill
- Example: Fletching above level 1 or with XP above 0.
- Result: marked as P2P.

### P2P Player Over the F2P Total Cap
- Total level above 1494.
- Result: marked as P2P.

## Testing Coverage

Current specs cover:
- Parser behavior for P2P evidence.
- Player verification behavior for F2P and P2P cases.
- False-positive mitigation around unstable activity-based parsing.

## Logging

The application logs verification outcomes such as:
- `Player #{name} marked as P2P: [reason]`
- `Player #{name} passed detailed P2P verification - marked as F2P`
- `Could not verify P2P hiscores content for #{name}: [error]`

## Related Documentation

- `docs/P2P_DETECTION_FIX.md`
- `docs/ACTIVITY_BASED_P2P_DETECTION_MITIGATION.md`
- `docs/ADMIN_GUIDE_P2P_VERIFICATION.md`
- `docs/archive/FALSE_P2P_LIST_REMOVAL_SUMMARY.md`
