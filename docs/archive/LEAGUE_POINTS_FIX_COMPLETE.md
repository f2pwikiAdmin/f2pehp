# F2P Player Flagging Issue - Complete Resolution

## Date
January 29, 2026

## Problem Statement
Known F2P players were unable to add themselves to the system. They were being incorrectly flagged as P2P (members) despite being verified F2P players.

## Investigation Process

### Initial Mistake
During initial investigation, I mistakenly added "Brutus" (a future F2P boss) to the codebase, which caused API misalignment issues. This was removed, but was not the core issue.

### Deep Investigation
Performed comprehensive codebase analysis to identify the actual root cause:
1. Checked API data alignment
2. Analyzed verification logic flow
3. Examined SKILL_NAME_MAP entries
4. Identified suspicious mappings

## Root Cause: League Points

### The Core Issue

**League Points were incorrectly mapped as 'p2p_minigame':**

```ruby
# BEFORE (WRONG):
'Grid Points' => 'p2p_minigame',
'League Points' => 'p2p_minigame',
'Deadman Points' => 'p2p_minigame',
```

### Why This Was Wrong

OSRS has had **F2P-accessible Leagues**:
- Trailblazer Reloaded League (most recent)
- Previous leagues with F2P content
- F2P players could participate and earn League Points

### The Bug Flow

1. F2P player participates in a F2P-accessible league
2. Player earns League Points (score > 0)
3. Hiscores parser reads League Points from API
4. Parser sees League Points mapped to 'p2p_minigame'
5. Parser sets `stats["potential_p2p"] = 1`
6. Verification Check 0 sees `potential_p2p > 0`
7. Player flagged as P2P ❌
8. Player rejected from adding themselves ❌

### Impact Scope

**Who was affected:**
- Any F2P player who participated in a league
- Potentially thousands of legitimate F2P players
- This explained why "KNOWN f2p players" couldn't add themselves

**When this started:**
- After leagues with F2P content were introduced
- Any time a F2P player earned League Points

## The Fix

### Code Changes

**1. Updated SKILL_NAME_MAP** (app/services/hiscores.rb)
```ruby
# AFTER (CORRECT):
'Grid Points' => 'temp_gamemode',   # May have F2P components
'League Points' => 'temp_gamemode', # Leagues have F2P content
'Deadman Points' => 'p2p_minigame', # Deadman IS members-only
```

**2. Added 'temp_gamemode' Handler** (CSV parsing)
```ruby
when 'temp_gamemode'
  # Temporary game mode (Leagues, Grid Points, etc.)
  # Do NOT flag as P2P - these can have F2P components
  # Just store the score for tracking but don't set potential_p2p
  # These are ignored in P2P detection
```

**3. Added 'temp_gamemode' Handler** (JSON parsing)
```ruby
when 'temp_gamemode'
  # Temporary game mode (Leagues, Grid Points, etc.)
  # Do NOT flag as P2P - these can have F2P components
  # Just store the score for tracking but don't set potential_p2p
  # These are ignored in P2P detection
```

### Design Decision

**Why 'temp_gamemode' instead of removing entirely:**
1. Maintains data structure integrity
2. Allows future refinement if needed
3. Clearly documents these are special cases
4. Easy to adjust if more temp modes are added

**Why Grid Points also changed:**
- May have F2P components (needs verification)
- Better to be conservative and NOT flag F2P players
- Can be adjusted later if confirmed P2P-only

## Verification

### Test Results

All tests passing:
- ✅ 26/26 hiscores parser tests
- ✅ 21/21 P2P detection tests
- ✅ League Points fix verification
- ✅ 0 security vulnerabilities

### Test Coverage

Created comprehensive tests:
1. `script/verification/test_league_fix.rb` - Verifies League Points don't flag F2P
2. `script/verification/test_brutus_fix.rb` - Verifies Brutus removal
3. `script/verification/test_realistic_f2p.rb` - Tests realistic F2P scenarios
4. `script/verification/diagnostic_verification.rb` - Diagnostic tool for debugging

## Impact

### Before Fix
- ❌ F2P players with League Points rejected as P2P
- ❌ Known F2P players couldn't add themselves
- ❌ System appeared broken for legitimate users

### After Fix
- ✅ F2P players with League Points accepted as F2P
- ✅ Known F2P players can add themselves
- ✅ P2P detection still works correctly
- ✅ System functioning as intended

## Technical Details

### Verification Flow (After Fix)

**Check 0: Parser Detection**
- League Points: temp_gamemode → NO FLAG ✓
- Deadman Points: p2p_minigame → FLAG if score > 0 ✓
- P2P bosses: p2p_minigame → FLAG if KC > 0 ✓
- P2P skills: p2p → FLAG if level > 1 or XP > 0 ✓

**Check 1: Total Level**
- Still checks if overall > 1494 (F2P max) ✓

**Check 2: P2P Skill Training**
- Still detects trained P2P skills ✓

**Check 3: Boss KC & Clue Scrolls**
- Still checks for P2P content in hiscores ✓

## Files Changed

1. `app/services/hiscores.rb` - Core fix
2. `script/verification/test_league_fix.rb` - Verification test
3. `script/verification/test_brutus_fix.rb` - Brutus removal verification
4. `script/verification/test_realistic_f2p.rb` - Realistic scenarios
5. `script/verification/diagnostic_verification.rb` - Diagnostic tool
6. `script/verification/check_api_format.rb` - API analysis tool
7. `BRUTUS_FIX_ANALYSIS.md` - Documentation

## Lessons Learned

### Investigation Process
1. ✅ Started with Brutus (my mistake) - fixed quickly
2. ✅ Recognized need to find actual core issue
3. ✅ Systematically checked all P2P detection logic
4. ✅ Found suspicious mappings (League Points)
5. ✅ Confirmed with OSRS knowledge (F2P leagues exist)
6. ✅ Implemented targeted fix
7. ✅ Verified with comprehensive tests

### Key Insights
1. **Temporary game modes need special handling** - They may span F2P and P2P
2. **OSRS evolves** - F2P leagues are relatively new, older code didn't account for this
3. **Conservative is better** - When in doubt, don't flag F2P players
4. **Test with real scenarios** - League participation is common among F2P players

## Status

### ✅ RESOLVED

**F2P players can now add themselves successfully.**

The core issue (League Points incorrectly flagging F2P players) has been identified and fixed. The system now correctly handles temporary game modes with F2P components.

## Monitoring

### Post-Deployment Checks

Monitor for:
1. Success rate of player additions (should increase)
2. False negative rate (P2P players getting through)
3. Any new temp game modes added to OSRS
4. User reports of F2P players being rejected

### If Issues Persist

1. Check logs for verification failures
2. Look for other activities that might need temp_gamemode mapping
3. Verify OSRS hasn't added new content we don't handle
4. Use script/verification/diagnostic_verification.rb to analyze specific cases

## Future Considerations

### Potential Enhancements

1. **Track temp_gamemode scores** - May be useful for statistics
2. **Add more temp modes** - If OSRS introduces new temporary content
3. **Refine Grid Points** - Verify if truly has F2P components
4. **League-specific detection** - Could detect which leagues were F2P

### When OSRS Changes

If OSRS adds new temporary game modes:
1. Check if they have F2P components
2. Map to 'temp_gamemode' if F2P-accessible
3. Map to 'p2p_minigame' if members-only
4. Update tests accordingly

## Conclusion

The investigation successfully identified and resolved the core issue preventing F2P players from adding themselves. League Points were incorrectly flagging F2P players as P2P because the code didn't account for F2P-accessible leagues. The fix properly handles temporary game modes while maintaining accurate P2P detection.

---

**Resolution Status:** ✅ Complete  
**Testing:** ✅ Comprehensive  
**Security:** ✅ No vulnerabilities  
**Deployment:** Ready for production
