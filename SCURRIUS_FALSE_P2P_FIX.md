# Fix Summary: False P2P Flagging for Scurrius

## Date
January 29, 2026

## Problem Statement
Legitimate F2P players like "5ent" were being falsely flagged as P2P (members) and removed from the F2P rankings. This was causing known F2P players to be kicked from the system.

## Root Cause
**Scurrius**, an F2P boss added to Old School RuneScape in January 2024, was incorrectly included in the `P2P_BOSSES` constant. The boss is located in Varrock Sewers and is fully accessible to F2P players, but the verification system was treating any player with Scurrius kill count as P2P.

### How the Bug Manifested
The P2P verification system uses a 4-point check:
1. **Check 0**: Parser detection of P2P content
2. **Check 1**: Total level and skill training analysis
3. **Check 2**: P2P boss KC detection (the problematic check)
4. **Check 3**: P2P clue scroll detection

In **Check 2** (lines 1226-1235 of `app/models/player.rb`), the system calls `check_p2p_hiscores_content` which fetches raw hiscores data and checks if the player has any activities listed in `P2P_BOSSES`. Since Scurrius was in this list, any F2P player who had killed Scurrius would be flagged as P2P.

## Solution

### Files Changed
1. **app/models/player.rb**
   - Removed 'Scurrius' from `P2P_BOSSES` constant (line 46)
   - Updated comment: "P2P bosses (excluding F2P bosses Obor, Bryophyta, and Scurrius)"

2. **lib/tasks/check_boss_kc.rake**
   - Removed 'Scurrius' from local `P2P_BOSSES` list (line 39)
   - Updated task description and output messages to mention Scurrius as F2P

3. **spec/models/player_p2p_detection_spec.rb**
   - Added test: "does not flag player as P2P based on Scurrius KC"
   - Added test: "does not flag player as P2P based on all F2P boss KCs (Obor, Bryophyta, Scurrius)"

4. **README.md**
   - Updated documentation to mention Scurrius alongside Obor and Bryophyta as F2P bosses

### What Was NOT Changed
- The `csv_activity_order` arrays in rake tasks were NOT changed because they need to maintain the exact order of the OSRS API response for proper parsing. Scurrius appears in these arrays only for parsing purposes, not for P2P detection.

## F2P Bosses in OSRS (2024-2026)
The three F2P bosses are:
1. **Obor** - Located in Edgeville Dungeon (requires Giant Key)
2. **Bryophyta** - Located in Varrock Sewers (requires Mossy Key)
3. **Scurrius** - Located in Varrock Sewers (The Rat King, added January 2024)

## Testing

### Automated Tests
All 23 P2P detection tests pass, including:
- Existing tests for Obor and Bryophyta
- New test for Scurrius KC only
- New test for all F2P boss KCs combined
- Edge case tests for missing helper fields
- Tests for maxed F2P accounts

### Manual Verification
Created and ran a verification script that confirmed:
- ✅ Scurrius is NOT in P2P_BOSSES
- ✅ Obor is NOT in P2P_BOSSES
- ✅ Bryophyta is NOT in P2P_BOSSES
- ✅ Sample P2P bosses (Wintertodt, Tempoross, Skotizo, etc.) ARE in P2P_BOSSES
- ✅ F2P_MAX_TOTAL constant is correct (1494)

### Code Review
- No issues found
- Changes are minimal and targeted
- Code quality maintained

### Security
- Changes consist only of removing a string from an array and updating documentation
- No new code paths or logic introduced
- No security vulnerabilities

## Impact

### Before Fix
- F2P players with Scurrius KC were flagged as P2P
- Players like "5ent" were incorrectly removed from F2P rankings
- False positive rate for F2P verification was artificially high

### After Fix
- F2P players with Scurrius KC are correctly identified as F2P
- Players with only F2P boss kills remain in F2P rankings
- Verification system accurately distinguishes F2P from P2P players

## Lessons Learned

1. **Stay Current with Game Updates**: Scurrius was added in January 2024 but was incorrectly classified as P2P in the codebase. Need to track OSRS updates more closely.

2. **Comprehensive Testing**: The bug was caught because of user reports. Should add tests whenever new bosses/content is added to OSRS.

3. **Documentation Matters**: Multiple files needed updates (code, tests, docs) to ensure consistency.

## Future Prevention

1. **Monitor OSRS Updates**: Watch for new F2P content releases
2. **Test New Content**: When new bosses/activities are added to OSRS, verify their F2P/P2P status
3. **Maintain Test Coverage**: Keep tests up-to-date with game content
4. **User Feedback**: Continue listening to user reports of false positives

## References

- OSRS Wiki: Scurrius - https://oldschool.runescape.wiki/w/Scurrius
- Scurrius is confirmed as F2P content, accessible in Varrock Sewers
- Released January 2024 as a mid-level F2P boss
- No membership requirement to access or kill

## Status
✅ **RESOLVED**

F2P players with Scurrius KC will no longer be falsely flagged as P2P. The issue affecting players like "5ent" has been fixed.
