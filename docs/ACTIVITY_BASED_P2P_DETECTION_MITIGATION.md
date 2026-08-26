# Temporary Mitigation: Activity-Based P2P Detection Disabled

**Status:** ACTIVE MITIGATION  
**Date:** 2026-01-29  
**Issue:** False P2P flagging due to unstable OSRS hiscores CSV activity parsing

## Summary

Activity-based P2P detection (boss KC and clue scrolls) has been **temporarily disabled** to prevent false positives. Only **skills-based detection** is now used for membership verification.

## Background

### The Problem

The OSRS `index_lite.ws` API returns hiscores data in CSV format with two sections:
1. **Skills (lines 0-24):** Fixed structure, stable and reliable
2. **Activities (lines 25+):** Variable-length lines, unstable format

The activities section has proven unreliable for positional parsing:
- Variable-length lines (e.g., `1037195,6`, `-1,2500`)
- Jagex can add/reorder activities without notice
- This causes misalignment when parsing by position
- Result: F2P players falsely flagged as P2P due to misaligned boss KC/clue data

### The Root Cause

Example of misalignment:
```
Expected: Line 52 = Zulrah KC (P2P boss)
Actual:   Line 52 = Obor KC (F2P boss) due to Jagex adding new activities

Result: F2P player with Obor KC gets flagged as P2P for "having Zulrah KC"
```

## The Mitigation

### What Changed

**1. Hiscores Parser (app/services/hiscores.rb)**
- CSV parser: Commented out `potential_p2p = 1` for `p2p_minigame` activities
- JSON parser: Commented out `potential_p2p = 1` for `p2p_minigame` activities
- Activities are still parsed and stored for future use
- Only skills now contribute to P2P detection

**2. Player Model (app/models/player.rb)**
- Commented out call to `check_p2p_hiscores_content` in `detailed_p2p_verification`
- Method still exists but is not invoked
- Added documentation noting temporary mitigation

### What Still Works (Skills-Only Detection)

Players are marked as P2P if:

1. **Parser detects trained P2P skills:** `potential_p2p > 0`
   - Any P2P skill (Fletching, Herblore, Agility, Thieving, Slayer, Farming, Hunter, Construction, Sailing) has level > 1 OR XP > 0

2. **Total level exceeds F2P maximum:** `overall_lvl > F2P_MAX_TOTAL` (1494)
   - F2P max: 15 skills × 99 + 9 P2P skills × 1 = 1494
   - Any level above 1494 means P2P skills are trained

3. **Deterministic reconciliation detects trained P2P skills:**
   - `overall_lvl > f2p_levels_sum + members_levels_sum`
   - Catches edge cases where individual skill levels don't match overall total

### What's Disabled

Players are **NOT** marked as P2P based on:
- Boss kill counts (excluding F2P boss checks like Obor/Bryophyta)
- Clue scroll completions (excluding F2P clues like beginner)
- Any other activity/minigame scores

**Note:** F2P activities (Obor KC, Bryophyta KC, LMS, beginner clues) are still parsed and stored but don't contribute to P2P detection.

## Impact

### Positive
✅ **Eliminates false positives** from unstable CSV activity parsing  
✅ **Maintains accurate detection** via skills-based evidence  
✅ **Conservative approach:** When in doubt, don't flag P2P  
✅ **No impact on F2P players** - they continue to be correctly identified

### Potential Edge Cases
⚠️ **Rare case:** A player who is P2P but has:
- All P2P skills at base level (level 1, 0 XP)
- AND total level ≤ 1494
- AND has only done P2P bosses/activities (no P2P skills trained)

This player would NOT be flagged as P2P under the mitigation. However:
- This scenario is extremely rare in practice
- Such a player would be detected on their next update when they train any P2P skill
- The benefit (preventing false positives) outweighs this rare edge case

## Future Solution

### Long-Term Fix

The permanent solution is to:
1. **Use name-based parsing** instead of position-based parsing
2. **Switch to JSON API** where available (more structured than CSV)
3. **Implement dynamic activity mapping** that adapts to API changes

This requires:
- Refactoring the hiscores parser to use `SKILL_NAME_MAP` for activities
- Adding validation to detect when Jagex adds/reorders activities
- Implementing fallback behavior when activities are in unexpected positions

### Re-enabling Activity-Based Detection

To re-enable in the future:
1. Uncomment the `potential_p2p = 1` lines in hiscores parsers
2. Uncomment the `check_p2p_hiscores_content` call in Player model
3. Update tests to expect activity-based detection
4. Verify no false positives with current API structure

Search for: `TEMPORARY MITIGATION` comments in the code

## Testing

### Test Coverage

**Added Tests:**
- `spec/models/player_p2p_detection_spec.rb`: Activity-based detection mitigation tests
- `spec/services/hiscores_spec.rb`: CSV parser mitigation test

**Updated Tests:**
- Updated JSON parser tests to expect activity-based detection disabled

**Test Results:**
- All 23 player P2P detection tests pass ✅
- All 29 hiscores parser tests pass ✅

### Manual Testing

To verify the mitigation works:

```ruby
# F2P player with high Obor KC (should NOT be flagged as P2P)
stats = Hiscores.fetch_stats("f2p_player_name")
player = Player.find_by(player_name: "f2p_player_name")
player.check_p2p_stats(stats)
# Expected: player.potential_p2p == 0

# P2P player with trained Fletching (should still be flagged as P2P)
stats = Hiscores.fetch_stats("p2p_player_name")
player = Player.find_by(player_name: "p2p_player_name")
player.check_p2p_stats(stats)
# Expected: player.potential_p2p == 1
```

## Related Documentation

- `archive/FALSE_P2P_FLAGGED_ANALYSIS.md` - Historical analysis of false P2P flagging
- `archive/VERIFICATION_LOGIC_UPDATE_SUMMARY.md` - Overview of 4-point verification system
- `P2P_VERIFICATION_UPDATE.md` - Detailed P2P verification documentation
- `ADMIN_GUIDE_P2P_VERIFICATION.md` - Admin guide for P2P verification

## Code Locations

**Modified Files:**
- `app/services/hiscores.rb`:
  - Lines 424-430: CSV parser `p2p_minigame` case
  - Lines 556-562: JSON parser `p2p_minigame` case
  
- `app/models/player.rb`:
  - Lines 1173-1178: `check_p2p_stats` method documentation
  - Lines 1223-1235: `detailed_p2p_verification` activity check (commented out)
  - Lines 1242-1247: `check_p2p_hiscores_content` method documentation

**Test Files:**
- `spec/models/player_p2p_detection_spec.rb`: Lines 760-856 (new mitigation tests)
- `spec/services/hiscores_spec.rb`: Lines 242-373 (CSV mitigation test), 544-594 (updated JSON tests)

## Monitoring

### How to Check if Mitigation is Working

1. **Check for false P2P flags:**
   ```ruby
   # Find players flagged as P2P without trained P2P skills
   Player.where(potential_p2p: 1)
         .where("overall_lvl <= ?", Player::F2P_MAX_TOTAL)
         .each do |p|
           # Manually verify if they have trained P2P skills
         end
   ```

2. **Monitor P2P detection rate:**
   ```ruby
   total = Player.count
   p2p = Player.where(potential_p2p: 1).count
   rate = (p2p.to_f / total * 100).round(2)
   puts "P2P rate: #{rate}% (#{p2p} / #{total})"
   ```

3. **Check logs for P2P flagging reasons:**
   ```bash
   grep "marked as P2P" log/production.log | tail -100
   ```

## Rollback Plan

If issues arise with the mitigation:

1. **Revert the changes:**
   ```bash
   git revert <commit-hash>
   ```

2. **Or manually uncomment:**
   - `app/services/hiscores.rb`: Uncomment `stats["potential_p2p"] = 1` lines
   - `app/models/player.rb`: Uncomment `check_p2p_hiscores_content` call

3. **Run tests to verify:**
   ```bash
   bundle exec rspec spec/models/player_p2p_detection_spec.rb
   bundle exec rspec spec/services/hiscores_spec.rb
   ```

## Support

For questions or issues:
- Review this document and related documentation
- Check test files for expected behavior
- Look for `TEMPORARY MITIGATION` comments in code
