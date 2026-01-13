# Auto-Add to False P2P Flagged Feature

## Overview
This is a **temporary feature** that allows newly created players to be automatically added to the `false_p2p_flagged` list, effectively bypassing the P2P detection system while still executing all P2P checks.

## Purpose
Temporarily reroute the "add player" functionality to also add players to the false flagged P2P list, making the change easily reversible and low impact. Importantly, **P2P experience checks and boss KC checks still execute normally**.

## How It Works

### Normal Player Creation Flow
1. User submits player name via web form
2. `Player.create_new` is called
3. P2P experience check runs (`initial_p2p_check`)
4. If player appears to be P2P, creation is rejected with 'p2p' message
5. If player appears to be F2P, player is created and boss KC data is stored

### With Auto-Add Feature Enabled
1. User submits player name via web form
2. `Player.create_new` is called
3. **P2P experience check STILL runs** (`initial_p2p_check` executes)
4. Player name is added to `runtime_false_p2p_flagged` list (in-memory)
5. Player is created regardless of P2P check result
6. **Boss KC checks STILL execute** (via `update_player` and Hiscores service)
7. Player's `potential_p2p` field may be set to 1, but they are treated as F2P due to being in the flagged list

### Key Behaviors
- **P2P checks execute**: The detection logic runs normally and updates stats
- **Boss KC checks execute**: Boss kill count data is processed and stored normally
- **Runtime storage**: Newly flagged players are stored in memory only
- **SQL filters**: Both config-based and runtime-flagged players are included in F2P queries
- **Fakes priority**: Players in the fakes list are NEVER treated as F2P, even if runtime-flagged

## Configuration

### Enabling the Feature
Edit `/config/initializers/assets.rb`:

```ruby
# TEMPORARY FEATURE: Auto-add newly created players to false_p2p_flagged list
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
# TEMPORARY FEATURE: Auto-add newly created players to false_p2p_flagged list
config.auto_add_to_false_p2p_flagged = false
```

Then restart the Rails application.

**Note**: Runtime-flagged players will no longer be treated as F2P after the feature is disabled. They will revert to normal P2P detection behavior based on their `potential_p2p` field.

## Runtime vs Persistent Flagging

### Runtime Flagging (Current Implementation)
- Players added to `config.runtime_false_p2p_flagged` array
- Stored in memory only
- Lost when application restarts
- Pros: No config file modifications, easy to clear by restarting
- Cons: List is lost on restart

### Persistent Flagging (Not Implemented)
- Would require writing to `config.false_p2p_flagged` in assets.rb
- Would persist across restarts
- Requires file write permissions and careful handling

The current implementation uses **runtime flagging** for simplicity and reversibility.

## Impact on Existing Functionality

### What Changes
1. New players can be created even if they appear to be P2P (when feature is enabled)
2. Runtime-flagged players are included in F2P rankings and filters
3. Runtime-flagged players appear in F2P-only leaderboards

### What Doesn't Change
1. P2P experience checks still execute and update `potential_p2p` field
2. Boss KC checks still execute and store boss kill counts
3. Existing players are not affected
4. Config-based `false_p2p_flagged` list continues to work normally
5. Fakes list still takes priority over all false_p2p_flagged lists

## Technical Details

### Code Changes
1. **config/initializers/assets.rb**
   - Added `config.auto_add_to_false_p2p_flagged` flag
   - Added `config.runtime_false_p2p_flagged` array

2. **app/models/player.rb**
   - `Player.create_new`: Adds players to runtime list when feature is enabled
   - `Player.sql_false_p2p_flagged`: Merges runtime and config lists
   - `Player.is_f2p?`: Checks runtime list in addition to config list

### Thread Safety
The current implementation appends to a shared array (`runtime_false_p2p_flagged`). In production with multiple workers, consider using a thread-safe data structure or Redis if concurrent access is a concern.

### Logging
When a player is added to the runtime list, a log message is generated:
```
[AUTO-ADD-FALSE-P2P] Added PlayerName to runtime false_p2p_flagged list (P2P check result: true/false)
```

## Testing
Tests are located in `spec/models/player_auto_add_false_p2p_spec.rb`:
- Feature enabled/disabled behavior
- SQL filter inclusion
- `is_f2p?` method behavior
- Fakes list priority
- P2P check execution verification
- Boss KC check execution verification

Run tests:
```bash
bundle exec rspec spec/models/player_auto_add_false_p2p_spec.rb
```

## Monitoring Runtime-Flagged Players

To see which players have been runtime-flagged during the current session:

```ruby
# In Rails console
F2POSRSRanks::Application.config.runtime_false_p2p_flagged
```

To clear the runtime list without restarting:

```ruby
# In Rails console
F2POSRSRanks::Application.config.runtime_false_p2p_flagged.clear
```

## Recommendations for Permanent Solution

If you want to make runtime-flagged players permanent (persist across restarts):

1. **Manual approach**: Copy player names from runtime list to config list
   ```ruby
   # Get runtime-flagged players
   runtime = F2POSRSRanks::Application.config.runtime_false_p2p_flagged
   
   # Manually add them to config.false_p2p_flagged array in assets.rb
   ```

2. **Rake task approach**: Create a rake task to export runtime list to a file
   ```ruby
   # In lib/tasks/false_p2p.rake
   task :export_runtime_false_p2p => :environment do
     runtime = F2POSRSRanks::Application.config.runtime_false_p2p_flagged
     File.write('runtime_false_p2p.txt', runtime.join("\n"))
   end
   ```

## Security Considerations

1. **P2P checks still execute**: The feature doesn't bypass detection, it just overrides the result
2. **Fakes priority maintained**: Known fakes are never treated as F2P
3. **Audit trail**: Log messages provide visibility into auto-flagged players
4. **Easy revert**: Simply toggle the flag and restart

## FAQ

**Q: Will existing players be affected?**
A: No, only newly created players are added to the runtime list.

**Q: What happens to runtime-flagged players when the feature is disabled?**
A: They revert to normal P2P detection based on their `potential_p2p` field value.

**Q: Can I see which players were auto-flagged?**
A: Yes, check the Rails logs for `[AUTO-ADD-FALSE-P2P]` messages or inspect `config.runtime_false_p2p_flagged`.

**Q: Are boss KC checks bypassed?**
A: No, boss KC checks execute normally and data is stored.

**Q: Are P2P experience checks bypassed?**
A: No, P2P experience checks execute normally and `potential_p2p` is set correctly.

**Q: Is this feature production-ready?**
A: Yes, but it's designed to be temporary. The runtime list doesn't persist across restarts.

## Troubleshooting

### Issue: Feature not working after enabling
- Solution: Ensure you restarted the Rails application after changing the config

### Issue: Players still being rejected as P2P
- Solution: Check that `config.auto_add_to_false_p2p_flagged` is set to `true`, not a string

### Issue: Runtime list is empty
- Solution: The list only persists during app lifetime. Check logs to confirm players are being added.

## Support
For questions or issues with this feature, check:
1. Rails logs for `[AUTO-ADD-FALSE-P2P]` messages
2. Test suite in `spec/models/player_auto_add_false_p2p_spec.rb`
3. This documentation file
