# Sailing Quest Detection Fix - Final Summary

## Date: January 29, 2026 (Updated)

## Problem
F2P players were being incorrectly rejected with the error "The player you wish to add is not a free to play account."

## Root Cause Discovery

### Initial Understanding (Incorrect)
Originally thought Sailing was simply missing from all F2P players.

### Actual Root Cause (Correct)
The Sailing skill has a **quest requirement** that unlocks it:
- **F2P players WITHOUT quest**: Sailing NOT in API response (24 skills, overall=837)
- **F2P players WITH quest**: Sailing appears at level 1 (25 skills, overall=838)
- **P2P players**: Sailing with trained level

This explains why only **SOME** F2P players were rejected (those without the quest)!

## False Positive Mechanism

### Scenario: F2P Player Without Sailing Quest
```
Parser expects: 25 skills (including Sailing)
API returns:    24 skills (no Sailing)
Result:         members_skill_count = 8, members_levels_sum = 8

Verification:
  overall = 837 (829 F2P + 8 P2P, but parser doesn't count missing Sailing)
  expected = 829 + 8 = 837  ✅ SHOULD PASS
  
BUT with old parser:
  Activities parsed from wrong line (off by one)
  OR members_count incorrect
  Result: FALSE POSITIVE ❌
```

### Scenario: F2P Player With Sailing Quest
```
Parser expects: 25 skills (including Sailing)
API returns:    25 skills (Sailing at level 1)
Result:         members_skill_count = 9, members_levels_sum = 9

Verification:
  overall = 838 (829 F2P + 9 P2P)
  expected = 829 + 9 = 838
  838 > 838 = FALSE ✅ CORRECTLY PASSES
```

## Solution Implemented

### Dynamic Sailing Detection
The parser now **detects** whether Sailing is present:

1. **Check line 24**: Does it exist and have 3 values?
   - 3 values (rank, level, xp) = **Skill** (Sailing present)
   - 2 values (rank, score) = **Activity** (Sailing absent)

2. **Adapt parsing**:
   - If Sailing present: Parse 25 skills, activities start at line 25
   - If Sailing absent: Parse 24 skills, activities start at line 24

3. **Verification adapts**:
   - Uses actual `members_skill_count` from parser (8 or 9)
   - Math works correctly for both scenarios

### Code Changes

**`app/services/hiscores.rb`:**
```ruby
# Detect if Sailing is actually present
sailing_present = false
if lines.length > 24
  line_24_values = lines[24].split(',').map(&:strip)
  sailing_present = line_24_values.length >= 3
end

# Parse appropriate number of skills
skills_to_parse = sailing_present ? csv_skill_order : csv_skill_order[0..-2]
```

**`app/models/player.rb`:**
```ruby
# F2P_MAX_TOTAL = 1494 (correct for all F2P, with or without quest)
# Verification uses actual members_count from parser
```

### New F2P Maximum
```
15 F2P skills × 99 levels = 1485
9 P2P skills × 1 level    = 9
Total F2P maximum         = 1494
```

**Note**: F2P players without Sailing quest will have overall < 1494, which is fine.

## Test Coverage

### New Test File: `hiscores_sailing_quest_spec.rb`
- ✅ F2P without Sailing quest (8 P2P skills, total 837)
- ✅ F2P with Sailing quest (9 P2P skills, total 838)  
- ✅ P2P with trained Sailing (detected as P2P)

### Updated Existing Tests
- Tests for "without Sailing" scenarios kept as-is (represent quest not done)
- Comments clarified to explain they represent F2P without quest
- All tests pass with dynamic detection

## P2P Skills Tracked
The parser now dynamically tracks:
- **Always**: Fletching, Herblore, Agility, Thieving, Slayer, Farming, Hunter, Construction (8)
- **Conditionally**: Sailing (9th skill, only if present in API)

## Impact

### Before Fix
- ❌ F2P players without Sailing quest → Rejected (false positive)
- ✅ F2P players with Sailing quest → Accepted
- ✅ P2P players → Rejected correctly

### After Fix
- ✅ F2P players without Sailing quest → Accepted
- ✅ F2P players with Sailing quest → Accepted
- ✅ P2P players with trained Sailing → Rejected correctly
- ✅ Activity parsing works correctly in both scenarios

## External Verification

See `EXTERNAL_VERIFICATION_GUIDE.md` for:
- Shell scripts to check Sailing presence
- Python scripts for detailed verification
- Test cases to try
- What to look for

## Related Files Changed
- `app/services/hiscores.rb` (dynamic detection)
- `app/models/player.rb` (F2P_MAX_TOTAL restored)
- `spec/services/hiscores_sailing_quest_spec.rb` (new tests)
- `spec/services/hiscores_spec.rb` (clarified comments)
- `spec/services/hiscores_f2p_levels_sum_spec.rb` (clarified comments)
- `EXTERNAL_VERIFICATION_GUIDE.md` (new doc)
- `SAILING_FIX_SUMMARY.md` (this file, updated)

## Notes for Future
- Sailing detection is automatic and robust
- System handles quest completion status gracefully
- No manual updates needed if more players complete quest
- Detection based on actual API response, not assumptions

---

**Fix Status**: ✅ Complete (Revised with Quest Detection)
**Commit**: Implement dynamic Sailing detection - handle both quest states

