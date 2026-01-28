# P2P Verification Update - false_p2p_flagged List

## Overview

This update transforms the `false_p2p_flagged` list from a simple "ignore list" into an active P2P verification system. Players in this list now undergo detailed verification checks during add/update operations to ensure they are truly F2P.

## What Changed

### Before
- Players in `false_p2p_flagged` list were **always** marked as F2P, regardless of their actual stats
- This was meant as a temporary fix for false positives
- Players who went P2P after being added to the list remained incorrectly marked as F2P

### After
- Players in `false_p2p_flagged` list undergo **detailed verification** during add/update operations
- The system checks:
  1. **P2P XP levels**: Verifies if total level exceeds F2P maximum (1494) or if any P2P skill is trained
  2. **P2P boss KC**: Checks for kill counts on P2P-only bosses (excluding F2P bosses Obor and Bryophyta)
  3. **P2P clue scrolls**: Checks for P2P clue scroll completions (excluding beginner clues)
- Players are only marked as F2P if they pass **all** verification checks
- Players who fail verification are marked as P2P and removed from the database

## Technical Details

### New Methods in Player Model

1. **`detailed_p2p_verification(stats)`** (instance method)
   - Runs comprehensive P2P checks for players in false_p2p_flagged list
   - Returns `true` if player has P2P content (should be marked as P2P)
   - Returns `false` if player is truly F2P

2. **`check_p2p_hiscores_content`** (instance method)
   - Fetches raw CSV data from OSRS hiscores API
   - Checks for P2P boss KC and clue scroll completions
   - Returns `true` if any P2P content found

3. **`initial_detailed_p2p_check(stats, name)`** (class method)
   - Similar to `detailed_p2p_verification` but for player creation
   - Only checks XP levels during creation (full check on first update)

### Modified Methods

1. **`check_p2p_stats(stats)`**
   - Now calls `detailed_p2p_verification` for players in false_p2p_flagged list
   - Updated logic ensures verification happens before marking players as F2P

2. **`initial_p2p_check(stats, name)`**
   - Now accepts optional `name` parameter
   - Calls `initial_detailed_p2p_check` for players in false_p2p_flagged list

### New Constants

- `F2P_MAX_TOTAL = 1494` - Maximum total level for F2P (15 skills × 99 + 9 P2P skills at level 1)
- `P2P_BOSSES` - Array of P2P-only boss names
- `P2P_CLUE_SCROLLS` - Array of P2P clue scroll types

## Verification Checks Explained

### 1. Total Level Check
- F2P maximum: 15 skills at 99 = 1485 levels
- Plus 9 P2P skills at base level 1 = 9 levels
- **Total F2P max: 1494 levels**
- Any total level > 1494 means P2P skills have been trained

### 2. P2P Skill Training Check
- Compares overall level with expected level (F2P sum + members count)
- If overall > expected, P2P skills have been trained beyond base level

### 3. P2P Boss KC Check
- Checks for kill counts on P2P-only bosses
- **Excludes F2P bosses**: Obor and Bryophyta
- Any P2P boss KC means player has accessed P2P content

### 4. P2P Clue Scrolls Check
- Checks for completions of P2P clue scrolls
- **Excludes beginner clues** (which are F2P)
- P2P clues: easy, medium, hard, elite, master

## Impact on Rankings

- **No immediate impact** on rankings
- Players in `false_p2p_flagged` continue to appear in F2P rankings via `is_f2p?` and `sql_f2p_filter` methods
- **Self-correcting over time**: When players update themselves, verification runs and their status may change
- Players who have gone P2P will be automatically detected and marked as P2P on their next update

## Benefits

1. **Automated verification**: No more manual checking of false_p2p_flagged players
2. **Self-correcting system**: Players who go P2P are automatically detected
3. **Non-disruptive**: Only affects players when they add/update themselves
4. **Comprehensive checks**: Uses the same logic as the existing rake tasks
5. **No database disruption**: Existing data remains unchanged until players update

## Migration Path

No migration required! The system works as follows:

1. **Existing players** in false_p2p_flagged list remain in rankings as F2P
2. **When a player updates**: Detailed verification runs automatically
3. **If verification fails**: Player is marked as P2P and removed from F2P rankings
4. **If verification passes**: Player remains as F2P

## Example Scenarios

### Scenario 1: Truly F2P Player Updates
- Player "TestPlayer" is in false_p2p_flagged
- Has total level 838 (all F2P skills, no P2P training)
- No P2P boss KC or clue scrolls
- **Result**: Passes verification, marked as F2P ✓

### Scenario 2: Player Who Went P2P Updates
- Player "FormerF2P" is in false_p2p_flagged
- Has total level 1510 (exceeds F2P max of 1494)
- Has trained Fletching to level 60
- **Result**: Fails verification, marked as P2P and removed ✗

### Scenario 3: Player Tries to Add Themselves
- Player "NewPlayer" is in false_p2p_flagged (perhaps had API issues before)
- Tries to add themselves to database
- Has P2P boss KC (e.g., Zulrah: 50 KC)
- **Result**: Verification runs, player is rejected as P2P ✗

## Testing

Updated tests in `spec/models/player_p2p_detection_spec.rb`:
- Added test for players who fail verification (have P2P content)
- Added test for players who pass verification (truly F2P)
- Both tests mock external API calls for reliability

## Logging

The system logs verification results:
- `Player #{name} marked as P2P: [reason]` - When verification fails
- `Player #{name} passed detailed P2P verification - marked as F2P` - When verification passes
- `Could not verify P2P hiscores content for #{name}: [error]` - When API check fails

## Future Improvements

Potential enhancements for future consideration:
1. Add verification results to player records for audit trail
2. Create admin dashboard to monitor verification results
3. Add rate limiting to prevent API abuse
4. Cache hiscores responses to reduce API calls
