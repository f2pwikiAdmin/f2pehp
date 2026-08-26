# Player Cleanup Guide

## Overview

The `players:cleanup_unavailable` rake task allows you to flag/hide players whose OSRS hiscores data is no longer available (e.g., deleted accounts, name changes). This is a **reversible operation** that preserves historical data while hiding these players from F2P rankings.

## Key Changes (February 2026)

Previously, this task **permanently deleted** players. Now it:
- **Flags/hides** players instead of deleting them
- Sets `potential_p2p = 1` (hides from F2P rankings)
- Sets `p2p_flag_reason = 'unavailable_hiscores'` (distinct from confirmed P2P)
- Preserves all historical data for review and potential restoration

## Usage

### Dry Run (Preview)

Always start with a dry run to preview what would be affected:

```bash
DRY_RUN=1 LIMIT=50 rake players:cleanup_unavailable
```

### Live Mode

After reviewing the dry run output:

```bash
rake players:cleanup_unavailable
```

This will:
1. Ask for confirmation (type 'yes' to proceed)
2. Check hiscores availability for each player
3. Flag unavailable players with `p2p_flag_reason = 'unavailable_hiscores'`
4. Show progress and summary statistics

### Advanced Options

```bash
# Process more players
LIMIT=500 rake players:cleanup_unavailable

# Adjust API call delay (default: 0.3s)
SLEEP=0.5 rake players:cleanup_unavailable

# Resume from a specific player ID
START_ID=1000 rake players:cleanup_unavailable

# Change progress logging frequency (default: every 50 players)
PROGRESS_EVERY=100 rake players:cleanup_unavailable

# Combine options
DRY_RUN=1 LIMIT=1000 SLEEP=0.5 START_ID=5000 rake players:cleanup_unavailable
```

## Querying Flagged Players

### Rails Console

```ruby
# Players flagged due to unavailable hiscores
Player.unavailable_hiscores_hidden.count
Player.unavailable_hiscores_hidden.pluck(:id, :player_name, :overall_lvl)

# Players flagged as confirmed P2P
Player.p2p_flagged.count

# All hidden players (both reasons)
Player.all_hidden.count
```

### SQL Query

```sql
-- Players flagged due to unavailable hiscores
SELECT id, player_name, overall_lvl, p2p_flag_reason, updated_at
FROM players
WHERE potential_p2p = 1
  AND p2p_flag_reason = 'unavailable_hiscores'
ORDER BY updated_at DESC;

-- Summary by reason
SELECT p2p_flag_reason, COUNT(*) as count
FROM players
WHERE potential_p2p >= 1
GROUP BY p2p_flag_reason;
```

## Reversing Flags (Unflagging)

If you discover a player was incorrectly flagged (e.g., they renamed their account), you can manually unflag them:

### Rails Console

```ruby
player = Player.find_by(player_name: 'PlayerName')
player.update(potential_p2p: 0, p2p_flag_reason: nil)
```

### SQL

```sql
UPDATE players
SET potential_p2p = 0, p2p_flag_reason = NULL
WHERE id = 12345;
```

## Best Practices

1. **Always start with a dry run** to preview affected players
2. **Use conservative LIMIT values** initially (e.g., 50-100)
3. **Monitor the output** for unexpected patterns
4. **Review flagged players periodically** to ensure accuracy
5. **Document any manual unflagging** for audit purposes

## Troubleshooting

### "ERROR: rate limited by OSRS API"

If you see rate limiting errors:
- Increase `SLEEP` parameter (e.g., `SLEEP=1.0`)
- Reduce `LIMIT` to process fewer players per run
- Wait a few minutes before resuming

### "Too many errors"

If you see excessive errors:
- Check your internet connection
- Verify OSRS hiscores API is accessible
- Check application logs for specific error messages

### "Player was incorrectly flagged"

If a legitimate F2P player was flagged:
1. Verify their hiscores are now available
2. Unflag them manually (see "Reversing Flags" above)
3. Consider if they renamed their account (new player entry may be needed)

## Related Tasks

```bash
# List unavailable players without flagging
rake players:list_unavailable

# Fix players with high total level not flagged as P2P
rake players:fix_high_total_unflagged

# Full P2P recheck for all players
rake players:full_recheck_p2p
```

## Schema Details

### New Column: `p2p_flag_reason`

- **Type**: `string`
- **Nullable**: `true`
- **Values**:
  - `'p2p'` - Confirmed P2P player (has trained members skills)
  - `'unavailable_hiscores'` - Hiscores data unavailable
  - `nil` - No flag or legacy flag (before this feature)

### Migration

```ruby
# db/migrate/20260210201021_add_p2p_flag_reason_to_players.rb
class AddP2pFlagReasonToPlayers < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :p2p_flag_reason, :string
  end
end
```

## Auditing

To track when players were flagged:

```sql
-- Recently flagged players
SELECT id, player_name, overall_lvl, p2p_flag_reason, updated_at
FROM players
WHERE potential_p2p = 1
  AND p2p_flag_reason = 'unavailable_hiscores'
  AND updated_at > NOW() - INTERVAL '7 days'
ORDER BY updated_at DESC;
```

## Support

For issues or questions:
1. Check this guide
2. Review application logs
3. Check the codebase:
   - Service: `app/services/player_cleanup_service.rb`
   - Model: `app/models/player.rb`
   - Rake task: `lib/tasks/diagnose_high_total_players.rake`
   - Tests: `spec/services/player_cleanup_service_spec.rb`
