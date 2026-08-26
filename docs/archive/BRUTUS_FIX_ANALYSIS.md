# F2P Player Flagging Issue - Root Cause Analysis and Fix

## Issue Date
January 29, 2026

## Problem Statement
Known F2P players were unable to add themselves to the system. They were being incorrectly flagged as P2P (members) despite being verified F2P players.

## Root Cause

### The Critical Bug
**Brutus** was added to the `csv_activity_order` arrays in multiple files, but **Brutus does not exist in the OSRS Hiscores API yet**. It's a future F2P boss that will be released "sometime in 2026."

### How This Caused the Issue

The OSRS Hiscores API returns data in a fixed CSV format:
- Lines 0-24: Skills
- Lines 25+: Activities (minigames, bosses, etc.)

The system parses this data using a `csv_activity_order` array that must **exactly match** the order returned by the API.

#### Example of the Misalignment:

**What the code expected (with Brutus):**
```
Line 25: Grid Points
Line 26: League Points
...
Line 51: Bryophyta (F2P boss)
Line 52: Brutus (F2P boss) ← DOESN'T EXIST IN API YET
Line 53: Callisto (P2P boss)
...
Line 84: Obor (F2P boss)
```

**What the API actually returns (without Brutus):**
```
Line 25: Grid Points
Line 26: League Points
...
Line 51: Bryophyta (F2P boss)
Line 52: Callisto (P2P boss) ← One position earlier than expected!
...
Line 83: Obor (F2P boss) ← One position earlier than expected!
```

### The Domino Effect

When the parser tried to read line 52, it expected Brutus but got Callisto instead. This shifted EVERY subsequent boss/activity by one position, causing:

1. **Wrong values parsed**: Obor's KC was read from the wrong line
2. **P2P bosses read as F2P**: Some P2P boss data might be read from F2P positions
3. **F2P players flagged as P2P**: When legitimate F2P activities were read from shifted positions

## Impact

- **Severity**: Critical - Prevents legitimate F2P players from using the system
- **Affected Users**: All F2P players trying to add themselves or update after the Brutus addition
- **Data Integrity**: Parser misalignment could cause incorrect P2P detection

## Solution

### Changes Made

Removed ALL references to Brutus from the codebase:

#### 1. Core Logic Files
- `app/services/hiscores.rb`
  - SKILL_NAME_MAP: Removed `'Brutus' => 'brutus_kc'`
  - csv_activity_order: Removed 'Brutus' from array
  - parse_stats_csv: Removed `when 'brutus_kc'` case handler
  - parse_stats: Removed `when 'brutus_kc'` case handler

- `app/models/player.rb`
  - csv_activity_order: Removed 'Brutus' from array
  - Updated comment to exclude Brutus from F2P boss list

#### 2. Test Files
- `spec/services/hiscores_spec.rb`
  - Removed Brutus test data
  - Removed Brutus expectations

#### 3. Rake Tasks
- `lib/tasks/check_boss_kc.rake`
- `lib/tasks/check_all_clue_scrolls.rake`
- `lib/tasks/check_clue_scrolls.rake`
- All updated to remove Brutus from csv_activity_order arrays

#### 4. Documentation
- `README.md`: Removed Brutus from F2P boss documentation

### Verification

Created `script/verification/test_brutus_fix.rb` to verify:
1. ✅ Brutus not in SKILL_NAME_MAP
2. ✅ Activity order correct (no offset)
3. ✅ Brutus not in P2P_BOSSES
4. ✅ F2P players correctly identified

All tests pass:
- 26/26 hiscores parser tests
- 21/21 P2P detection tests
- 0 security vulnerabilities

## Prevention

### When to Add Brutus Back

Only add Brutus when:
1. Jagex officially releases Brutus in OSRS
2. The OSRS Hiscores API includes Brutus in its response
3. Confirmed via actual API testing that Brutus appears in the expected position

### How to Add Safely

1. Test with real API data first
2. Add to SKILL_NAME_MAP
3. Add to csv_activity_order in CORRECT alphabetical position
4. Add case handlers for brutus_kc
5. Update tests with actual API response format
6. Verify alignment with diagnostic script

## Lessons Learned

1. **API Alignment is Critical**: Any mismatch between expected and actual API format causes cascading failures
2. **Future Features Need Verification**: Don't add future content until it exists in the live API
3. **Test with Real Data**: Parser logic must match actual API responses, not theoretical structures
4. **Context Matters**: "Brutus is the only new F2P boss sometime in 2026" was future context, not current state

## Timeline

- **Unknown Date**: Brutus added to codebase (future feature)
- **January 29, 2026**: Issue reported - F2P players can't add themselves
- **January 29, 2026**: Root cause identified - API misalignment due to Brutus
- **January 29, 2026**: Fixed - All Brutus references removed
- **January 29, 2026**: Verified - All tests passing, F2P detection working

## Status

✅ **RESOLVED**

F2P players can now add themselves successfully. The verification system is correctly aligned with the OSRS Hiscores API.
