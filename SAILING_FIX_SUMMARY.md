# Sailing Skill Fix Summary

## Date: January 29, 2026

## Problem
F2P players were being incorrectly rejected with the error "The player you wish to add is not a free to play account."

## Root Cause
The Sailing skill was causing false positive P2P detections:

1. **Parsing Issue**: The hiscores parser expected 25 skills (including Sailing)
2. **API Inconsistency**: F2P players may not have Sailing in their API response (only 24 skills returned)
3. **Two Problems Result**:
   - **Activity Misalignment**: Activities parsed from wrong CSV line (off-by-one error)
   - **Skill Count Mismatch**: Only 8 P2P skills counted instead of expected 9

4. **False Positive Logic**:
   ```
   Verification check: overall > (f2p_sum + members_sum)
   Expected:  829 + 8 = 837
   Actual F2P player: 838 (includes Sailing at level 1)
   Result: 838 > 837 → FALSE POSITIVE! ❌
   ```

## Why Sailing Is Problematic
- Sailing was added to OSRS on November 19, 2025
- Database columns for Sailing were removed on December 24, 2025 (migration: 20251224175155)
- Indicates Sailing was found to be problematic for F2P tracking
- F2P players may not consistently have Sailing in their hiscores API responses

## Solution Implemented

### Code Changes
1. **Removed Sailing from Parser** (`app/services/hiscores.rb`):
   - Removed from `csv_skill_order` (line 318)
   - Commented out in `SKILL_NAME_MAP` (line 46)
   - Activities now start at correct line (24 instead of 25)

2. **Updated F2P Maximum** (`app/models/player.rb`):
   ```ruby
   # OLD: F2P_MAX_TOTAL = 1494  # 15×99 + 9×1
   # NEW: F2P_MAX_TOTAL = 1493  # 15×99 + 8×1
   ```

3. **Updated Tests**:
   - `spec/services/hiscores_spec.rb`
   - `spec/services/hiscores_f2p_levels_sum_spec.rb`
   - All tests now expect 8 P2P skills instead of 9

### New F2P Maximum
```
15 F2P skills × 99 levels = 1485
8 P2P skills × 1 level    = 8
Total F2P maximum         = 1493 (was 1494)
```

**Note**: Any documentation referencing 1494 should now use 1493.

## P2P Skills Tracked
The parser now tracks these 8 P2P skills:
1. Fletching
2. Herblore
3. Agility
4. Thieving
5. Slayer
6. Farming
7. Hunter
8. Construction

**Sailing is omitted** to avoid false positives.

## Impact
- ✅ F2P players will no longer be falsely rejected
- ✅ Activities parse from correct CSV line
- ✅ Member skill count matches reality (8 not 9)
- ✅ Verification logic works correctly
- ⚠️ Players with Sailing trained will still be correctly detected as P2P via other checks

## Testing
All tests updated to reflect 8 P2P skills:
- CSV parsing tests
- JSON parsing tests
- F2P level sum calculation tests
- Maxed F2P player tests (now uses 1493 instead of 1494)

## Related Files Changed
- `app/services/hiscores.rb`
- `app/models/player.rb`
- `spec/services/hiscores_spec.rb`
- `spec/services/hiscores_f2p_levels_sum_spec.rb`
- `TESTING_DIRTCRAB.md`
- `SAILING_FIX_SUMMARY.md` (this file)

## Notes for Future
- If Sailing becomes consistently available in F2P hiscores, it can be re-added
- Database migrations show Sailing columns were deliberately removed (Dec 24, 2025)
- This fix aligns with that decision to not track Sailing

---

**Fix Status**: ✅ Complete
**Commit**: Fix F2P player rejection by removing Sailing skill from parser
