# PR #87 Reinstatement - Fix Summary

## Issue
Players with F2P-accessible activities like "PvP Arena - Rank" and "Collections Logged" were being incorrectly flagged as P2P (pay-to-play), causing legitimate F2P players to be excluded from F2P hiscores rankings. Additionally, after the initial PR #87 merge, updating players caused HTTP 500 errors due to unknown attribute assignment.

## Root Cause

### False P2P Flagging
In the `SKILL_NAME_MAP` configuration:
- `'PvP Arena - Rank' => 'p2p_minigame'` 
- `'Collections Logged' => 'p2p_minigame'`

When F2P players participated in these F2P-accessible activities, the hiscores parser detected them as P2P minigames (score > 0) and set `potential_p2p = 1`, incorrectly flagging them as P2P members.

### HTTP 500 Error
The original PR #87 attempted to fix this by mapping these activities to specific names (`pvp_arena_rank`, `collections_logged`), which caused the parser to store keys like:
- `pvp_arena_rank_score`
- `pvp_arena_rank_rank`
- `collections_logged_score`
- `collections_logged_rank`

However, these keys are not database columns. When `Player#update_player` called `self.attributes = stats`, Rails raised `ActiveModel::UnknownAttributeError`, causing 500 errors on player create/update operations.

## The Fix

### 1. Correct Activity Mappings (hiscores.rb)

Updated `SKILL_NAME_MAP` to treat these as F2P activities:
```ruby
'PvP Arena - Rank' => 'pvp_arena_rank',      # Changed from 'p2p_minigame'
'Collections Logged' => 'collections_logged', # Changed from 'p2p_minigame'
```

Added handling in both CSV and JSON parsers:
```ruby
when 'pvp_arena_rank'
  # PvP Arena - Rank is F2P (F2P players can participate)
  # Store as score/rank pair without flagging as P2P
  stats[:pvp_arena_rank_score] = score
  stats[:pvp_arena_rank_rank] = rank
when 'collections_logged'
  # Collections Logged is F2P (F2P players can have collection log entries)
  # Store as score/rank pair without flagging as P2P
  stats[:collections_logged_score] = score
  stats[:collections_logged_rank] = rank
```

**Key Point:** These activities do NOT set `stats["potential_p2p"] = 1`, preventing false P2P flagging.

### 2. Flexible Hiscores Storage (Database + Player Model)

**Migration:** Added `hiscores_extras` column to `players` table
```ruby
# db/migrate/20260129165315_add_hiscores_extras_to_players.rb
add_column :players, :hiscores_extras, :text
```

**Player Model:** Added JSON serialization and smart attribute splitting
```ruby
class Player < ActiveRecord::Base
  serialize :hiscores_extras, JSON
  
  # In update_player method:
  # 1. Get valid column names
  valid_columns = self.class.column_names.map(&:to_sym)
  
  # 2. Separate known attributes from extras
  extras = {}
  stats_to_assign = {}
  
  stats.each do |key, value|
    if valid_columns.include?(key.to_sym) || valid_columns.include?(key.to_s.to_sym)
      stats_to_assign[key] = value  # Known column
    else
      extras[key.to_s] = value       # Store in extras
    end
  end
  
  # 3. Store extras in hiscores_extras column (auto-serialized as JSON)
  if extras.any?
    stats_to_assign[:hiscores_extras] = extras
  end
  
  # 4. Assign only known attributes to model (prevents UnknownAttributeError)
  self.attributes = stats_to_assign
end
```

**Benefits:**
- Future-proof: New OSRS activities automatically stored without schema changes
- No crashes: Unknown keys stored safely in `hiscores_extras` JSON column
- Backward compatible: Existing known columns continue to work as before

### 3. Robustness Improvements

Added nil-safety to virtual stat calculations in Player model:
- `calc_combat`: Falls back to database values for missing skill levels
- `calc_skill_ehp`: Handles nil XP with `(xp || 0).to_i`
- `calc_tiered_ehp`: Handles nil skill_xp safely
- `time_to_max`: Falls back to database values for missing skills
- `calc_bonus_xps`: Skips nil skills during bonus calculations
- `calc_ehp`: Falls back to database values for missing skills

These prevent crashes during partial player updates.

### 4. Comprehensive Test Coverage

**Hiscores Tests (`spec/services/hiscores_spec.rb`):**
- CSV parsing: F2P player with PvP Arena rank and Collections Logged does NOT get flagged as P2P
- JSON parsing: Same verification for JSON API format
- Verified correct score/rank storage for both activities

**Player Model Tests (`spec/models/player_update_spec.rb`):**
- Player update with unknown keys (pvp_arena_rank_score, collections_logged_score) does NOT crash
- Unknown keys properly stored in `hiscores_extras` JSON column
- Known attributes stored in their respective columns (not in extras)

## Test Results

✅ **30/30 tests passing:**
- 28 hiscores service tests (including 2 new PR #87 tests)
- 2 new player model tests for extras handling

✅ **Database migrations:**
- Development (PostgreSQL): Successfully applied
- Test (SQLite): Successfully applied
- Schema updated with `hiscores_extras` column

✅ **Code review:** No issues found

✅ **Security:** No vulnerabilities (defensive programming improvements)

## Impact

### Before Fix
- ❌ F2P players with PvP Arena rank or Collections Logged were incorrectly flagged as P2P
- ❌ Player create/update operations crashed with HTTP 500 errors
- ❌ Legitimate F2P players excluded from rankings

### After Fix
- ✅ F2P players with these activities correctly identified as F2P
- ✅ Player create/update operations work without errors
- ✅ New OSRS activities handled gracefully via `hiscores_extras` column
- ✅ System is more robust with nil-safety improvements
- ✅ False P2P flagging resolved for affected players

## Files Changed

1. **app/services/hiscores.rb**
   - Updated `SKILL_NAME_MAP` mappings for PvP Arena and Collections Logged
   - Added handling in `parse_stats_csv` method
   - Added handling in `parse_stats` method (JSON)

2. **app/models/player.rb**
   - Added `serialize :hiscores_extras, JSON`
   - Modified `update_player` to split known attributes vs extras
   - Added nil-safety to virtual stat calculations
   - Fixed JSON serialization (use hash directly, not .to_json)

3. **db/migrate/20260129165315_add_hiscores_extras_to_players.rb**
   - New migration: Added `hiscores_extras` text column

4. **db/schema.rb**
   - Updated with new `hiscores_extras` column

5. **spec/services/hiscores_spec.rb**
   - Added PR #87 test section with CSV and JSON parsing tests

6. **spec/models/player_update_spec.rb**
   - New test file for unknown key handling

## Deployment Notes

This fix is **safe to deploy**:
- ✅ Database migration required (adds new column)
- ✅ Backward compatible (existing data unaffected)
- ✅ No API changes
- ✅ All tests passing
- ✅ Improves system robustness

### Recommended Post-Deployment Actions

1. **Review existing players:** Some F2P players may have been incorrectly flagged as P2P before this fix. Consider running:
   ```ruby
   # Find players with PvP Arena or Collections Logged data in hiscores_extras
   # who are currently flagged as P2P but should be F2P
   Player.where(potential_p2p: 1).find_each do |player|
     # Re-check P2P status with the fixed logic
     player.update_player
   end
   ```

2. **Monitor logs:** Watch for any new activities added by Jagex that appear in `hiscores_extras`

## Conclusion

PR #87 has been successfully reinstated with fixes for both the false P2P flagging issue and the HTTP 500 error. The solution:

1. ✅ Correctly identifies PvP Arena and Collections Logged as F2P activities
2. ✅ Prevents false P2P flagging of legitimate F2P players
3. ✅ Eliminates 500 errors on player create/update
4. ✅ Future-proofs the system with flexible `hiscores_extras` storage
5. ✅ Improves robustness with nil-safety in virtual stat calculations

The system now handles new OSRS activities gracefully without requiring schema changes, while maintaining accurate F2P/P2P classification.
