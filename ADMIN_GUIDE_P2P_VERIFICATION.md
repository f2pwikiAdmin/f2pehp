# Admin Guide: P2P Verification System

## Overview

The false_p2p_flagged list is now an **active verification system** that automatically checks players for P2P content when they add or update themselves in the database.

## How It Works

### For Players Already in the Database

When a player in the `false_p2p_flagged` list updates their stats:

1. **Automatic verification runs** checking:
   - P2P XP levels (total level vs F2P maximum)
   - P2P boss kill counts (excluding F2P bosses)
   - P2P clue scroll completions (excluding beginner)

2. **If verification passes** (player is truly F2P):
   - Player remains in database with `potential_p2p = 0`
   - Continues to appear in F2P rankings

3. **If verification fails** (player has P2P content):
   - Player is marked with `potential_p2p = 1`
   - Removed from F2P rankings
   - Logs show reason for P2P marking

### For New Players Being Added

When someone tries to add a player in the `false_p2p_flagged` list:

1. **Verification runs during creation** checking XP levels
2. **If they pass**: Player is added to database as F2P
3. **If they fail**: Player is rejected with "not a free to play account" message
4. **Full verification** runs on their first update (includes boss KC/clues)

## Managing the false_p2p_flagged List

### Adding Players to the List

Edit `config/initializers/assets.rb` line 21:

```ruby
config.false_p2p_flagged = ["PlayerName1", "PlayerName2", ...]
```

**When to add a player:**
- They were falsely flagged as P2P by the old detection system
- You've manually verified they are truly F2P
- They have F2P boss KC (Obor/Bryophyta) but were flagged

**What happens when you add them:**
- They'll appear in F2P rankings immediately (via `sql_f2p_filter`)
- When they update, automatic verification will confirm they're F2P
- If they've actually gone P2P since being added, verification will catch it

### Removing Players from the List

**When to remove a player:**
- Verification has confirmed they're actually P2P
- They've been permanently removed from the database
- You've manually verified they don't need special handling

**How to check if a player should be removed:**

Run the existing rake tasks (they still work for analysis):

```bash
# Check if players have trained P2P skills
bundle exec rake players:check_false_p2p_flagged

# Check if players have P2P boss KC
bundle exec rake players:check_boss_kc

# Check if players have P2P clue scrolls
bundle exec rake players:check_clue_scrolls
```

These tasks will identify players who should be removed from the list.

## Monitoring Verification

### Check Rails Logs

The verification system logs its actions:

```ruby
# When player passes verification
"Player #{name} passed detailed P2P verification - marked as F2P"

# When player fails due to high total level
"Player #{name} marked as P2P: Total level #{level} exceeds F2P max (1494)"

# When player fails due to trained P2P skills
"Player #{name} marked as P2P: Has trained P2P skills (X levels beyond base)"

# When player fails due to P2P boss KC or clues
"Player #{name} marked as P2P: Has P2P boss KC or clue scrolls"
"Player #{name} has P2P content: [Boss/Clue Name] = [Count]"

# When verification can't complete
"Could not verify P2P hiscores content for #{name}: [error]"
```

### Finding Players Who Failed Verification

```ruby
# In Rails console
players_in_list = Player.where("LOWER(player_name) IN (?)", 
  F2POSRSRanks::Application.config.downcase_false_p2p_flagged)
  
# Find ones marked as P2P (failed verification)
failed = players_in_list.where("potential_p2p > 0")
failed.each do |p|
  puts "#{p.player_name} - potential_p2p: #{p.potential_p2p}"
end
```

## Common Scenarios

### Scenario: Player Reports They Can't Update

**Symptom**: Player in false_p2p_flagged list says update fails

**Likely cause**: They've gone P2P since being added

**Steps:**
1. Check logs for their verification failure reason
2. Manually verify their stats on OSRS hiscores
3. If truly P2P: Remove from false_p2p_flagged list
4. If truly F2P: Investigate what verification check is failing

### Scenario: F2P Player False Flagged

**Symptom**: Legitimate F2P player marked as P2P

**Steps:**
1. Manually verify on OSRS hiscores (check boss KC, clues, skills)
2. If truly F2P: Add to false_p2p_flagged list
3. Tell player to update their stats
4. Verification will run and mark them as F2P

### Scenario: Want to Clean Up false_p2p_flagged List

**Steps:**
1. Run the three rake tasks to identify P2P players:
   ```bash
   bundle exec rake players:check_false_p2p_flagged
   bundle exec rake players:check_boss_kc
   bundle exec rake players:check_clue_scrolls
   ```

2. Review output - it will list players who should be removed

3. Edit `config/initializers/assets.rb` to remove those names

4. Restart application to load new config

## Differences from Old System

### Before
- Players in list were **always** marked as F2P
- Manual checking required via rake tasks
- No automatic updates when players went P2P

### Now
- Players in list undergo **automatic verification**
- Verification happens during add/update operations
- Self-correcting as players update themselves
- Rake tasks still available for manual analysis

## Best Practices

1. **Regularly review logs** for verification failures
2. **Run rake tasks monthly** to identify players to remove from list
3. **Don't over-add players** - only add when genuinely false positives
4. **Let the system work** - verification happens automatically on update
5. **Monitor for API failures** - verification needs OSRS API access

## Troubleshooting

### High Number of Verification Failures

**Possible causes:**
- OSRS API is down/slow
- Many players in list have gone P2P
- Network connectivity issues

**Actions:**
- Check OSRS hiscores API availability
- Review recent log entries for patterns
- Consider temporary rate limiting if API struggling

### Player Stuck as P2P Despite Being F2P

**Possible causes:**
- Old data in database
- API returned wrong data during verification
- Player has F2P boss KC being misdetected

**Actions:**
- Check player's current OSRS hiscores manually
- Review log for their last verification attempt
- If truly F2P: add to false_p2p_flagged and have them update

### Verification Not Running

**Possible causes:**
- Configuration not loaded
- Player not actually in false_p2p_flagged list (check case sensitivity)
- Code error in verification logic

**Actions:**
- Check application logs for errors
- Verify config loaded: `F2POSRSRanks::Application.config.false_p2p_flagged`
- Check player name matches exactly (case-insensitive but spelling must match)

## Need Help?

If you encounter issues:
1. Check Rails logs for verification messages
2. Run rake tasks to see current state
3. Verify OSRS API is accessible
4. Review P2P_VERIFICATION_UPDATE.md for technical details
