# Example: Enabling Auto-Add to False P2P Flagged Feature

## Quick Start Guide

### Step 1: Enable the Feature
Edit `/config/initializers/assets.rb` (around line 27):

```ruby
# TEMPORARY FEATURE: Auto-add newly created players to false_p2p_flagged list
# Change this from false to true:
config.auto_add_to_false_p2p_flagged = true  # <-- Change this line
```

### Step 2: Restart Your Application
```bash
# Development
rails server

# Production (example with Passenger)
touch tmp/restart.txt

# Production (example with systemd)
sudo systemctl restart your-rails-app
```

### Step 3: Add Players Normally
Go to your web interface and add players as usual through the "Add Player" form. Players will now be created even if they appear to be P2P members.

### Step 4: Monitor Runtime-Flagged Players
```bash
# In Rails console
rails console

# Check which players have been runtime-flagged
F2POSRSRanks::Application.config.runtime_false_p2p_flagged
# => ["playername1", "playername2", ...]
```

### Step 5: Check Logs
Look for log entries showing the auto-add behavior:
```
[AUTO-ADD-FALSE-P2P] Added TestPlayer to runtime false_p2p_flagged list (P2P check result: true)
```

## Example Scenario

### Before Enabling Feature
```
User: Adds "TestP2PPlayer" who has trained P2P skills
System: Runs P2P check -> detects P2P training
Result: Player creation rejected with message "The player you wish to add is not a free to play account."
```

### After Enabling Feature
```
User: Adds "TestP2PPlayer" who has trained P2P skills
System: Runs P2P check -> detects P2P training
System: Adds player to runtime_false_p2p_flagged list
Result: Player created successfully! Appears in F2P rankings.
Log: [AUTO-ADD-FALSE-P2P] Added TestP2PPlayer to runtime false_p2p_flagged list (P2P check result: true)
```

## Important Notes

### What Still Happens (Good!)
✅ P2P experience checks execute normally
✅ Boss KC checks execute normally
✅ Player stats are calculated correctly
✅ `potential_p2p` field is set correctly (may be 1 for P2P)
✅ Fakes list still takes priority

### What Changes
🔄 Players who would normally be rejected as P2P are now created
🔄 These players appear in F2P rankings and leaderboards
🔄 They are treated as F2P for filtering purposes

### Limitations
⚠️ Runtime list is cleared when app restarts
⚠️ Runtime list is stored in memory (not persisted to disk)
⚠️ May require additional memory if many players are added

## Reverting the Feature

### Step 1: Disable the Feature
Edit `/config/initializers/assets.rb`:

```ruby
config.auto_add_to_false_p2p_flagged = false  # <-- Change back to false
```

### Step 2: Restart Your Application
```bash
rails server  # or your production restart command
```

### Step 3: What Happens to Runtime-Flagged Players?
- They are no longer treated as F2P
- They revert to normal P2P detection (based on `potential_p2p` field)
- If you want to keep them as F2P permanently, you must manually add them to the config-based `false_p2p_flagged` list

## Making Runtime-Flagged Players Permanent

If you want to persist the runtime-flagged players:

### Option 1: Manual Copy
```bash
# In Rails console
runtime_players = F2POSRSRanks::Application.config.runtime_false_p2p_flagged
puts runtime_players.inspect

# Then manually add these names to config.false_p2p_flagged array in assets.rb
```

### Option 2: Export to File
```bash
# In Rails console
runtime = F2POSRSRanks::Application.config.runtime_false_p2p_flagged
File.write('runtime_flagged_players.txt', runtime.join("\n"))

# Then review the file and add desired players to config.false_p2p_flagged
```

## Troubleshooting

### Problem: Players still being rejected as P2P
**Solution**: 
- Verify `config.auto_add_to_false_p2p_flagged = true` (not a string)
- Ensure you restarted the application
- Check Rails logs for errors

### Problem: Can't see runtime-flagged players in console
**Solution**:
- Make sure at least one player has been added since enabling the feature
- Runtime list is empty on startup - it only fills as players are created
- Check logs for `[AUTO-ADD-FALSE-P2P]` messages

### Problem: Feature not working after restart
**Solution**:
- Runtime list is cleared on restart - this is expected behavior
- If you want persistence, use the config-based `false_p2p_flagged` list

## Testing the Feature

### Manual Test
1. Enable the feature
2. Restart the application
3. Try to add a known P2P player (one with P2P skills trained)
4. Verify player is created successfully
5. Check logs for auto-add message
6. Check that player appears in F2P rankings

### Automated Test
```bash
bundle exec rspec spec/models/player_auto_add_false_p2p_spec.rb
```

## Questions?

Refer to the full documentation in `AUTO_ADD_FALSE_P2P_FEATURE.md`
