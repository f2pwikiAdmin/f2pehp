# Sailing P2P Detection Fix

## Summary

Updated documentation and comments in the codebase to clarify that the presence of Sailing (or 25 skills) does NOT indicate P2P membership. Both F2P and P2P accounts have 25 skills in the OSRS hiscores API response.

## Background

Previously, there was confusion about whether the presence of the Sailing skill indicated P2P membership. Live testing of the OSRS hiscores API confirmed:
- **F2P accounts** return 25 skill lines (lines 0-24), with Sailing at `-1,1,0` (unranked, level 1, 0 XP)
- **P2P accounts** also return 25 skill lines, with Sailing showing training if the player has trained it

## Changes Made

### 1. Updated Comments in `app/services/hiscores.rb`

#### `parse_stats_csv` method (lines 290-301)
Added clarification that:
- Both F2P and P2P accounts return 25 skill lines
- The presence of 25 skills does NOT indicate P2P membership
- P2P detection is based on whether members-only skills show training beyond default (level > 1 or xp > 0)
- Unranked P2P skills at level 1 with 0 XP do NOT flag as P2P

#### P2P skill detection logic (lines 372-382)
Enhanced comment to explicitly state:
- Lists all members-only skills including Sailing
- Emphasizes that presence alone does NOT indicate membership
- Only flags as P2P if skill shows evidence of training beyond default
- Clarifies that unranked skills at `-1,1,0` are NOT flagged

#### `parse_stats` method (JSON parser) (lines 466-477)
Added similar clarification for the JSON parser path.

### 2. Updated `app/models/player.rb`

#### F2P_MAX_TOTAL constant (lines 21-30)
Expanded comment to show detailed calculation:
- Lists all 15 F2P skills
- Lists all 9 P2P skills (including Sailing)
- Shows calculation: (15 × 99) + (9 × 1) = 1494
- Added note that both F2P and P2P accounts have all 25 skills in hiscores

### 3. Updated Test Comments in `spec/services/hiscores_spec.rb`

#### "handles unranked sailing correctly" test (lines 386-387)
Removed outdated calculation formula comment that suggested a different algorithm.
Updated to clarify that the condition `lvl > 1 || xp > 0` evaluates to false for unranked Sailing.

## Verification

The logic itself was **already correct** and did not need changes:

```ruby
when 'p2p'
  stats[:members_skill_count] += 1
  stats[:members_levels_sum] += lvl
  if lvl > 1 || xp > 0  # This correctly handles unranked skills
    stats["potential_p2p"] = 1
  end
```

### Test Cases Verified:
1. **F2P with unranked Sailing** (`-1,1,0`): Does NOT flag as P2P ✓
2. **P2P with trained Sailing** (level 30, 15000 XP): DOES flag as P2P ✓
3. **Maxed F2P** (total level 1494): Does NOT flag as P2P ✓

## Impact

These changes are **documentation-only**:
- No functional code changes
- No changes to test expectations (tests were already correct)
- Clarifies the existing correct behavior
- Prevents future confusion about Sailing and skill counts

## Conclusion

The P2P detection logic correctly handles Sailing and all other members-only skills. The mere presence of these skills in the hiscores API response does NOT indicate membership. Only actual training (level > 1 or xp > 0) triggers the P2P flag.
