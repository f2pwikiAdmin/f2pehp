# Admin Guide: Universal P2P Verification System

## Overview

The system now uses **comprehensive P2P verification for ALL players**. Every player (new and existing) undergoes the same detailed checks when they add or update themselves in the database.

## How It Works

### For ALL Players (New and Existing)

When ANY player adds or updates their stats:

1. **Special cases checked first**:
   - **Fakes list**: Always marked as P2P (skip verification)
   - **False-banned list**: Always marked as F2P (skip verification)

2. **All other players** (including those in false_p2p_flagged):
   - Undergo comprehensive 4-check verification
   - Checking: parser detection, total level, skill training, boss KC/clues

3. **Verification results**:
   - **All checks pass**: Player marked as F2P (potential_p2p = 0)
   - **Any check fails**: Player marked as P2P (potential_p2p = 1)

### What This Means

**Before (Old System):**
- Regular players: Basic verification
- false_p2p_flagged players: Automatic F2P (bypass)
- Inconsistent detection across player types

**After (New System):**
- ALL players: Comprehensive 4-check verification
- false_p2p_flagged players: Same verification as everyone else
- Consistent, accurate detection for all

## Managing the false_p2p_flagged List

### What the List Does Now

The false_p2p_flagged list **no longer bypasses verification**. Instead:
- Players in this list go through the **same comprehensive verification** as all other players
- The list's main function is now for **ranking display** (via `sql_f2p_filter`)
- Players in the list appear in F2P rankings even if temporarily flagged as P2P

### When to Add Players

Add players to false_p2p_flagged when:
- They were falsely flagged in the past (before new system)
- You want them to appear in F2P rankings despite temporary P2P flag
- They have historical F2P status you want to preserve in rankings

**Note**: Adding to the list does NOT bypass verification anymore!

### When to Remove Players

Remove players from false_p2p_flagged when:
- They've been confirmed as P2P through verification
- They no longer play or have been removed from database
- You want to clean up the list

### How to Edit the List

Edit `config/initializers/assets.rb` line 21:

```ruby
config.false_p2p_flagged = ["PlayerName1", "PlayerName2", ...]
```

Restart application after changes to load new configuration.

## Verification Checks Explained

ALL players now undergo these 4 checks:

### Check 0: Parser Detection
- Hiscores parser detected P2P content (`potential_p2p > 0`)
- Catches most obvious cases (trained P2P skills, P2P minigames)
- **Fast**: No additional API calls needed

### Check 1: Total Level
- Maximum F2P total: 1494 (15 F2P skills × 99 + 9 P2P skills × 1)
- Any total > 1494 means P2P skills trained
- **Deterministic**: Clear pass/fail

### Check 2: P2P Skill Training
- Compares overall level with expected F2P level
- Detects if any P2P skill trained beyond base level
- **Precise**: Catches even 1 level of P2P training

### Check 3: Boss KC & Clue Scrolls
- Fetches raw hiscores CSV data
- Checks P2P bosses (excludes Obor/Bryophyta)
- Checks P2P clues (excludes beginner)
- **Comprehensive**: Catches P2P access even without skill training

## Monitoring Verification

### Check Rails Logs

The system logs ALL player verifications:

```ruby
# When any player passes verification
"Player #{name} passed detailed P2P verification - marked as F2P"

# When parser detects P2P
"Player #{name} marked as P2P: Parser detected P2P content (potential_p2p = X)"

# When total level exceeds F2P max
"Player #{name} marked as P2P: Total level #{level} exceeds F2P max (1494)"

# When P2P skills trained
"Player #{name} marked as P2P: Has trained P2P skills (X levels beyond base)"

# When P2P boss KC or clues found
"Player #{name} marked as P2P: Has P2P boss KC or clue scrolls"
"Player #{name} has P2P content: [Boss/Clue Name] = [Count]"

# When API check fails
"Could not verify P2P hiscores content for #{name}: [error]"
```

### Finding Verification Results

```ruby
# In Rails console

# Find recently updated players
recent = Player.where("updated_at > ?", 1.hour.ago)

# Check their P2P status
recent.each do |p|
  puts "#{p.player_name}: potential_p2p = #{p.potential_p2p}"
end

# Find players marked as P2P in last hour
new_p2p = Player.where("updated_at > ? AND potential_p2p > 0", 1.hour.ago)
new_p2p.each do |p|
  puts "#{p.player_name} newly marked as P2P"
end
```

## Common Scenarios

### Scenario: New Player Can't Add Themselves

**Symptom**: Player tries to add themselves, gets "not a free to play account" message

**Likely cause**: Player has P2P content (skills, boss KC, or clues)

**Steps:**
1. Check logs for their verification failure reason
2. Manually verify their stats on OSRS hiscores
3. If truly P2P: This is correct behavior
4. If truly F2P but verification failed: Investigate which check is triggering

### Scenario: Existing Player Can't Update

**Symptom**: Player update fails or marks them as P2P

**Likely cause**: They've gone P2P since last update

**Steps:**
1. Check logs for verification failure reason
2. Verify their current stats on OSRS hiscores
3. If truly P2P: This is correct behavior (system working as intended)
4. If truly F2P: Check which verification check is failing

### Scenario: Want to Monitor Verification Success Rate

**Steps:**
1. Check logs for verification messages
2. Count passes vs failures over time period
3. Investigate patterns in failures

```bash
# Example log analysis
grep "passed detailed P2P verification" production.log | wc -l  # Passes
grep "marked as P2P:" production.log | wc -l  # Failures
```

### Scenario: Player in false_p2p_flagged Marked as P2P

**Symptom**: Player in false_p2p_flagged list shows as P2P in database

**This is normal!** The list doesn't bypass verification anymore.

**What happens:**
- Player goes through verification like everyone else
- If they fail (have P2P content), they're marked as P2P
- They still appear in F2P rankings (due to list membership)
- When they update again, verification runs again

**Action:** If they're confirmed P2P, consider removing from list

## Differences from Old System

### Before (Old System)
- Regular players: Basic checks only
- false_p2p_flagged players: Automatic F2P (bypass verification)
- Different rules for different player types
- Rake tasks needed for manual analysis

### Now (New System)
- **ALL players: Same comprehensive verification**
- false_p2p_flagged players: No special treatment in verification
- Consistent rules for everyone
- Rake tasks still available for analysis

## Best Practices

1. **Trust the verification**: It's comprehensive and catches edge cases
2. **Monitor logs regularly**: Catch any unusual patterns
3. **Don't over-use false_p2p_flagged**: It's mainly for ranking display now
4. **Let the system work**: Verification happens automatically
5. **Investigate failures**: If legitimate F2P players fail, there may be a bug

## Troubleshooting

### High Verification Failure Rate

**Possible causes:**
- OSRS API issues (slow/down)
- Legitimate P2P players trying to add themselves
- Bug in verification logic

**Actions:**
- Check OSRS hiscores API availability
- Review recent verification logs for patterns
- Sample-check some failures manually on hiscores

### Player Stuck as P2P Despite Being F2P

**Possible causes:**
- Had P2P content when last verified
- API returned wrong data during verification
- Verification logic bug

**Actions:**
- Check their current OSRS hiscores manually
- Review log for their last verification attempt
- If truly F2P: May need code investigation

### Verification Not Running

**Possible causes:**
- Code error in verification methods
- Configuration not loaded
- Database connection issues

**Actions:**
- Check application logs for errors
- Verify Player model loaded correctly
- Test verification in Rails console

## Running Old Rake Tasks

The rake tasks still work for manual analysis:

```bash
# Check players for P2P XP (analyzes all players, not just false_p2p_flagged)
bundle exec rake players:check_false_p2p_flagged

# Check for P2P boss KC
bundle exec rake players:check_boss_kc

# Check for P2P clue scrolls
bundle exec rake players:check_clue_scrolls
```

**Note**: These are for analysis only. The new system runs these checks automatically for all players during add/update.

## Migration Notes

### No Action Required

The system automatically applies to:
- **New players**: Verified during creation
- **Existing players**: Verified on next update
- **All player types**: Same verification for everyone

### Gradual Rollout

As players naturally update themselves:
- They get the new comprehensive verification
- P2P players are automatically detected
- F2P players are correctly marked
- Database becomes more accurate over time

## Need Help?

If you encounter issues:
1. Check Rails logs for verification messages
2. Test verification in Rails console
3. Verify OSRS API is accessible
4. Review P2P_VERIFICATION_UPDATE.md for technical details
5. Check if player is in special lists (fakes, false_banned)
