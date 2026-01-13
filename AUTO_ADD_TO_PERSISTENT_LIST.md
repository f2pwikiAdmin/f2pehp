# Auto-Add to Persistent False P2P Flagged List Feature

## Overview
This feature allows newly created players to be automatically added to the persistent `false_p2p_flagged` list in the config file after P2P experience and boss KC checks are executed. Once added, players are treated as F2P permanently.

## Purpose
Temporarily reroute the "add player" functionality to add players to the persistent false_p2p_flagged list after verification, making the change easily reversible while executing all P2P checks.

## How It Works

### Normal Player Creation Flow (Feature Disabled)
1. User submits player name via web form
2. `Player.create_new` is called
3. Hiscores data fetched from Jagex API
4. P2P experience check runs (`initial_p2p_check`)
5. If player appears to be P2P → creation rejected with 'p2p' message
6. If player appears to be F2P → player created
7. `update_player` executes (boss KC checks run here)

### With Auto-Add Feature Enabled
1. User submits player name via web form
2. `Player.create_new` is called
3. Hiscores data fetched from Jagex API
4. **P2P experience check STILL runs** (`initial_p2p_check`)
5. If auto-add enabled → **player name added to persistent config.false_p2p_flagged list**
   - Written to config/initializers/assets.rb file
   - Added to in-memory config immediately
6. Player created
7. **`update_player` executes (boss KC checks STILL run)**
8. Player treated as F2P permanently (persists across restarts)

### Key Behaviors
- **P2P checks execute**: The detection logic runs normally before adding to list
- **Boss KC checks execute**: Boss kill count data is processed and stored normally
- **Persistent storage**: Players written to config file, not just memory
- **No restart needed to see effect**: In-memory config updated immediately
- **Fakes priority**: Players in the fakes list are NEVER treated as F2P

## Configuration

### Enabling the Feature
Edit `/config/initializers/assets.rb` (around line 24):

```ruby
# Set to true to enable automatic addition to persistent false_p2p_flagged list
config.auto_add_to_false_p2p_flagged = true
```

Then restart the Rails application:
```bash
# Development
rails server

# Production
# Restart using your production deployment method
```

### Disabling the Feature (Reverting)
Edit `/config/initializers/assets.rb`:

```ruby
# Set to false to disable automatic addition
config.auto_add_to_false_p2p_flagged = false
```

Then restart the Rails application.

**Note**: Players already added to the config file will remain there. They won't be automatically removed when you disable the feature.

## What Gets Written to Config File

When a player is added, their name is appended to the `config.false_p2p_flagged` array:

```ruby
config.false_p2p_flagged = [
  "existing_player1", 
  "existing_player2",
  # ... existing players ...
  "NewlyAddedPlayer"  # <- Added by auto-add feature
]
```

## Monitoring

### Check Logs
Watch for log entries showing when players are added:
```bash
grep "AUTO-ADD-FALSE-P2P" log/production.log
```

Log format:
```
[AUTO-ADD-FALSE-P2P] Added PlayerName to persistent false_p2p_flagged list
```

### Review Config File
Check which players have been added by viewing the config file:
```bash
cat config/initializers/assets.rb | grep -A 500 "config.false_p2p_flagged = \["
```

## Impact on Existing Functionality

### What Changes
1. New players can be created even if they appear to be P2P (when feature is enabled)
2. Players are permanently added to false_p2p_flagged list in config file
3. These players appear in F2P rankings and filters permanently

### What Doesn't Change
1. P2P experience checks still execute and update `potential_p2p` field
2. Boss KC checks still execute and store boss kill counts
3. Existing players are not affected
4. Config-based `false_p2p_flagged` list continues to work normally
5. Fakes list still takes priority over false_p2p_flagged list

## Technical Details

### Code Changes

**app/models/player.rb**

1. **New method: `add_to_false_p2p_flagged_config(player_name)`**
   - Reads config/initializers/assets.rb
   - Adds player name to config.false_p2p_flagged array
   - Writes updated content back to file
   - Updates in-memory config immediately
   
2. **Updated: `create_new` method**
   - Executes P2P check before auto-add logic
   - Calls `add_to_false_p2p_flagged_config` if feature enabled
   - Creates player and runs normal update flow

3. **Simplified: `sql_false_p2p_flagged` and `is_f2p?`**
   - Removed runtime list logic (no longer needed)
   - Only checks persistent config.false_p2p_flagged

**config/initializers/assets.rb**

- Removed `runtime_false_p2p_flagged` array
- Updated comments to reflect persistent storage
- Kept `auto_add_to_false_p2p_flagged` flag

### Thread Safety
File writes use Ruby's File.write which is atomic on most filesystems. For high-concurrency environments, consider:
- Using a file lock mechanism
- Moving to database storage
- Using a message queue

### Error Handling
If writing to config file fails:
- Error is logged
- Player creation continues normally
- Player may not be added to false_p2p_flagged list
- Check logs for `[AUTO-ADD-FALSE-P2P] Error` messages

## Removing Players from the List

If you want to remove players added by this feature:

1. **Manually edit config file**: Remove player names from the array
2. **Restart application**: Changes take effect after restart

Example:
```ruby
# Before
config.false_p2p_flagged = ["player1", "player2", "unwanted_player", "player3"]

# After removing unwanted_player
config.false_p2p_flagged = ["player1", "player2", "player3"]
```

## Use Cases

### Use Case 1: Mass Player Import
Enable the feature when importing many players who may be falsely flagged:
1. Enable auto-add feature
2. Import players via web interface
3. All players added to persistent list
4. Disable feature when done
5. Review and clean up list if needed

### Use Case 2: Testing
Test P2P detection without rejecting players:
1. Enable auto-add in development
2. Add test players
3. Verify P2P checks execute correctly
4. Verify boss KC data stored
5. Players remain in system for further testing

## FAQ

**Q: Will players remain in the list after I disable the feature?**
A: Yes, players are written to the config file and persist permanently until manually removed.

**Q: Can I see which players were added by the feature?**
A: Check the logs for `[AUTO-ADD-FALSE-P2P]` messages or review the config.false_p2p_flagged array.

**Q: Are P2P checks bypassed?**
A: No, P2P experience checks execute normally before adding to the list.

**Q: Are boss KC checks bypassed?**
A: No, boss KC checks execute normally during player update.

**Q: What if the config file becomes too large?**
A: Consider periodically reviewing and cleaning up the list, or implementing database storage for production use.

**Q: Is this feature safe for production?**
A: Yes, but monitor the config file size and review additions regularly.

**Q: Can I manually add players to the list without enabling the feature?**
A: Yes, you can manually edit the config.false_p2p_flagged array and restart.

## Troubleshooting

### Issue: Players not being added to list
**Solution**: 
- Check logs for error messages
- Verify config file is writable
- Ensure auto_add_to_false_p2p_flagged = true
- Restart application after changing config

### Issue: Config file syntax error after additions
**Solution**:
- Restore from backup
- Check for missing commas or quotes in array
- Use `ruby -c config/initializers/assets.rb` to verify syntax

### Issue: Too many players in list
**Solution**:
- Disable feature temporarily
- Review and clean up list manually
- Consider database storage for large lists

## Security Considerations

1. **File Permissions**: Ensure config file has appropriate write permissions
2. **Audit Trail**: Review logs regularly to track additions
3. **P2P Checks Run**: Detection logic executes normally
4. **Fakes Priority**: Known fakes are never treated as F2P
5. **Backup Config**: Keep backups before enabling in production

## Recommendations

1. **Development/Staging First**: Test feature in non-production environment
2. **Monitor Logs**: Watch for auto-add messages
3. **Review Regularly**: Check config file for unexpected additions
4. **Backup Config**: Keep version control or backups of config file
5. **Document Additions**: Note why feature was enabled and for how long

## Support

For issues or questions:
1. Check Rails logs for `[AUTO-ADD-FALSE-P2P]` messages
2. Verify config file syntax with `ruby -c config/initializers/assets.rb`
3. Review this documentation
