# Player Cleanup Task Refactoring - Implementation Summary

## Overview

Refactored the `players:cleanup_unavailable` rake task to **flag/hide** players instead of permanently deleting them, making the operation reversible and providing better auditability.

## Problem Statement

The original implementation permanently deleted players whose hiscores data was unavailable. This caused several issues:
1. **Irreversible**: No way to recover accidentally deleted players
2. **Data Loss**: Lost all historical data for these players
3. **No Distinction**: Couldn't differentiate between confirmed P2P players and players with unavailable data
4. **Auditability**: Couldn't review who was affected or when

## Solution

Instead of deleting, we now:
1. Set `potential_p2p = 1` (hides from F2P rankings)
2. Set `p2p_flag_reason = 'unavailable_hiscores'` (distinct marker)
3. Preserve all player data for review/restoration

## Implementation Details

### Database Changes

**New Column**: `p2p_flag_reason` (string, nullable)
```ruby
# Migration: db/migrate/20260210201021_add_p2p_flag_reason_to_players.rb
add_column :players, :p2p_flag_reason, :string
```

**Purpose**: Distinguish why a player was flagged:
- `'p2p'` - Confirmed P2P (has trained members skills)
- `'unavailable_hiscores'` - Hiscores data unavailable
- `nil` - No flag or legacy flag

### Model Changes (app/models/player.rb)

**New Constant**:
```ruby
P2P_FLAG_REASONS = {
  p2p: 'p2p',
  unavailable_hiscores: 'unavailable_hiscores'
}.freeze
```

**New Scopes**:
```ruby
scope :unavailable_hiscores_hidden, -> { where(potential_p2p: 1, p2p_flag_reason: P2P_FLAG_REASONS[:unavailable_hiscores]) }
scope :p2p_flagged, -> { where(potential_p2p: 1, p2p_flag_reason: P2P_FLAG_REASONS[:p2p]) }
scope :all_hidden, -> { where(potential_p2p: 1) }
```

### Service Changes (app/services/player_cleanup_service.rb)

**Before** (deleted players):
```ruby
player.destroy
deleted = true
```

**After** (flags players):
```ruby
player.update_columns(
  potential_p2p: 1,
  p2p_flag_reason: Player::P2P_FLAG_REASONS[:unavailable_hiscores]
)
flagged = true
Rails.logger.info "Player #{player.player_name} (ID: #{player.id}) flagged as unavailable_hiscores"
```

**Result Tracking**:
- Changed `deleted` to `flagged` throughout
- Updated logging to reflect flagging action

### Rake Task Changes (lib/tasks/diagnose_high_total_players.rake)

**Updated Messaging**:
- Task description: "Flag/hide players..." instead of "Clean up players..."
- Mode indicator: "LIVE (will flag/hide)" instead of "LIVE (will delete)"
- Confirmation prompt: "will flag/hide players" instead of "will permanently delete"
- Summary output: "Successfully flagged/hidden" instead of "Successfully deleted"

### Test Coverage (spec/services/player_cleanup_service_spec.rb)

**Updated Existing Tests**:
- Changed assertions from checking deletion to checking flagging
- Verified players still exist after flagging
- Checked `potential_p2p` and `p2p_flag_reason` values

**New Tests**:
1. **Reason Setting**: Verifies correct reason is set when flagging
2. **Scope Querying**: Tests `unavailable_hiscores_hidden` scope works correctly
3. **Reason Distinction**: Ensures different flag reasons are properly distinguished

**Test Results**: 16 examples, 0 failures

### Documentation

**Updated Files**:
1. `HIGH_TOTAL_LEVEL_ISSUE.md` - Updated Option 2 to reflect new behavior
2. Created `PLAYER_CLEANUP_GUIDE.md` - Comprehensive admin guide

**Guide Contents**:
- Usage examples with all configuration options
- Querying flagged players (Rails console and SQL)
- Reversing flags (unflagging process)
- Best practices and troubleshooting
- Schema details and auditing queries

## Testing & Verification

### Unit Tests
✅ All 16 service tests pass
✅ Covers dry run, live mode, multiple players, error handling, progress logging
✅ Tests new scopes and reason distinction

### Integration Test
✅ Rake task runs successfully in dry run mode
✅ Outputs correct messaging
✅ Task description updated in `rake -T`

### Manual Security Review
✅ No SQL injection vulnerabilities (uses ActiveRecord hash conditions)
✅ No mass assignment issues (uses `update_columns` with hardcoded constants)
✅ Proper authorization (requires confirmation)
✅ Data integrity preserved (reversible operations)
✅ Input validation on environment variables

## Benefits

### 1. Reversibility
- Can unflag players if needed
- Simple restoration: `player.update(potential_p2p: 0, p2p_flag_reason: nil)`

### 2. Auditability
- Query who was flagged: `Player.unavailable_hiscores_hidden`
- See when flagged: check `updated_at`
- Track reason: `p2p_flag_reason` column

### 3. Distinguishability
- Can differentiate between:
  - Confirmed P2P players (`p2p_flag_reason = 'p2p'`)
  - Players with unavailable hiscores (`p2p_flag_reason = 'unavailable_hiscores'`)

### 4. Data Preservation
- No data loss from accidental/premature flagging
- Historical stats remain intact
- Can re-enable players if they return

## Usage Examples

### Dry Run
```bash
DRY_RUN=1 LIMIT=50 rake players:cleanup_unavailable
```

### Live Mode
```bash
rake players:cleanup_unavailable
```

### Query Affected Players
```ruby
# Rails console
Player.unavailable_hiscores_hidden.count
Player.unavailable_hiscores_hidden.pluck(:id, :player_name)
```

### Unflag a Player
```ruby
player = Player.find_by(player_name: 'PlayerName')
player.update(potential_p2p: 0, p2p_flag_reason: nil)
```

## Breaking Changes

**None** - The refactoring maintains backward compatibility:
- Same rake task name and interface
- Same environment variables
- Same dry run behavior
- Same confirmation prompts

## Migration Path

### For Existing Deployments

1. **Deploy changes** (includes migration)
2. **Run migration**: `rake db:migrate`
3. **Existing flagged players**: Will have `p2p_flag_reason = nil` (legacy flags)
4. **New flags**: Will have `p2p_flag_reason = 'unavailable_hiscores'`

### Backward Compatibility

- Existing scopes and queries still work
- `potential_p2p = 1` still hides players from rankings
- No changes needed to existing flagging logic for confirmed P2P players

## Files Changed

1. `db/migrate/20260210201021_add_p2p_flag_reason_to_players.rb` - Migration
2. `db/schema.rb` - Updated schema
3. `app/models/player.rb` - Added constant and scopes
4. `app/services/player_cleanup_service.rb` - Changed deletion to flagging
5. `lib/tasks/diagnose_high_total_players.rake` - Updated messaging
6. `spec/services/player_cleanup_service_spec.rb` - Updated and added tests
7. `HIGH_TOTAL_LEVEL_ISSUE.md` - Updated documentation
8. `PLAYER_CLEANUP_GUIDE.md` - New comprehensive guide (created)

## Code Review Feedback Addressed

1. **Constant Ordering**: Moved `P2P_FLAG_REASONS` before scopes for better readability
2. **Scope Clarity**: Changed `all_hidden` from `>= 1` to `= 1` for explicitness
3. **Comments**: Added clarifying comment for `all_hidden` scope

## Future Enhancements (Optional)

1. **Automatic Unflagging**: If a player's hiscores become available again during a later update
2. **Bulk Unflagging**: Admin UI or rake task to unflag multiple players at once
3. **Flag History**: Track all flag changes over time (requires additional table)
4. **Notification**: Alert admins when players are flagged
5. **Dashboard**: Admin panel showing flagging statistics and trends

## Acceptance Criteria

✅ Running `bundle exec rake players:cleanup_unavailable` no longer deletes players
✅ It marks them via existing p2p-flagging mechanism with distinct reason
✅ Possible to query/list players flagged due to unavailable hiscores
✅ Tests pass (16/16)
✅ Documentation updated
✅ No breaking changes
✅ No security vulnerabilities introduced

## Conclusion

The refactoring successfully transforms a destructive operation into a reversible one while maintaining backward compatibility. The implementation follows Rails best practices, includes comprehensive test coverage, and provides clear documentation for administrators.
