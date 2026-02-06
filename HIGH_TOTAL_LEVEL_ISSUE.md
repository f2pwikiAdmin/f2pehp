# High Total Level Players Issue - Explanation and Solutions

## The Problem

You have approximately 2,000 players on your website with `overall_lvl > 1494` (the F2P maximum), and when running the `full_recheck_p2p` rake task, about 2,000 players were "skipped" due to "no hiscores data".

## Why This Happens

### 1. What "No Hiscores Data" Means

When the `full_recheck_p2p` task shows "Skipped (no hiscores data)", it means:

- The OSRS hiscores API returned a **404 error** for that player
- This happens when:
  - The player account doesn't exist
  - The player was banned or deleted by Jagex
  - The player name is invalid/misspelled
  - The player hasn't logged in recently (unranked accounts)

The relevant code in `app/services/base.rb`:
```ruby
rescue OpenURI::HTTPError => e
  # 404, no content - returns nil
```

### 2. Why Players with High Total Levels Exist

The total level check (`overall_lvl > 1494` → flag as P2P) only runs in two scenarios:

1. **During player creation** - via `initial_detailed_p2p_check()`
2. **During player update** - via `check_p2p_stats()` when fresh hiscores data is fetched

**The problem:**
- If a player's hiscores data becomes unavailable (deleted/banned account), they can't be updated
- Old players added before the check existed remain in the database with stale data
- Database records persist even when the OSRS account is gone

### 3. The Connection

The ~2,000 players with high total levels and the ~2,000 skipped due to "no hiscores data" are likely **the same players**:
- They have stale data showing high total levels
- Their OSRS accounts are no longer accessible (deleted/banned)
- The recheck task can't fetch their data to verify/update their P2P status

## Solutions

### Option 1: Fix Unflagged Players (Recommended)

If you have players with `overall_lvl > 1494` but `potential_p2p = 0`, fix them immediately:

```bash
# Diagnose the issue first
rake players:diagnose_high_total

# Fix unflagged players (sets potential_p2p = 1)
rake players:fix_high_total_unflagged
```

**What this does:**
- Updates all players with `overall_lvl > 1494` to have `potential_p2p = 1`
- Ensures database consistency (high total = P2P)
- Safe operation - only updates the flag

### Option 2: Remove Unavailable Players (Optional)

If you want to clean up players whose OSRS accounts no longer exist:

```bash
# First, list some unavailable players to see what you're dealing with
LIMIT=50 rake players:list_unavailable

# Then manually delete them if needed
# (You would need to create a cleanup task for bulk deletion)
```

**Considerations:**
- Historical data would be lost
- If these are legitimate players who just haven't logged in, you'd lose them
- More aggressive approach - use with caution

### Option 3: Update All Players (Comprehensive)

Run the full recheck with proper handling:

```bash
# Recheck all players - will skip unavailable ones
rake players:full_recheck_p2p

# Check results
rake players:diagnose_high_total
```

**What this does:**
- Fetches fresh data for all accessible players
- Updates their P2P status based on current data
- Skips players whose data is unavailable (keeping their old data)

## Understanding the Numbers

If you see:
- **2,000 players with total > 1494**
- **2,000 players skipped (no hiscores data)**

This suggests:
1. These are likely the same 2,000 players
2. Their accounts no longer exist in OSRS
3. Database has stale data from when they did exist
4. They should probably have `potential_p2p = 1` based on their stored total level

## Recommended Action Plan

1. **Immediate**: Fix the inconsistency
   ```bash
   rake players:diagnose_high_total
   rake players:fix_high_total_unflagged
   ```

2. **Regular**: Run periodic rechecks
   ```bash
   # Daily/weekly cron job
   rake players:full_recheck_p2p
   ```

3. **Optional**: Consider cleanup policy
   - Decide if you want to keep unavailable players
   - Create a policy for removing old/banned accounts
   - Document your decision

## Prevention

To prevent this in the future:

1. ✅ **Already implemented**: Total level check in `detailed_p2p_verification()` method
   - Check: `if overall > F2P_MAX_TOTAL` (1494)
2. ✅ **Already implemented**: Direct P2P skill evidence check
   - Iterates through `MEMBERS_ONLY_SKILLS` checking for XP > 0
3. ✅ **Already implemented**: Parser sets `potential_p2p = 1` for trained P2P skills

The system is working correctly for new/updated players. The issue is just with old/stale data in the database.

## Technical Details

### Database Query to Find Problem Players

```ruby
# Players with high total but not flagged as P2P
Player.where("overall_lvl > ?", Player::F2P_MAX_TOTAL)
      .where("potential_p2p != 1 OR potential_p2p IS NULL")
      .count

# Check a specific player
player = Player.find_by(player_name: "SomePlayer")
player.overall_lvl  # Shows their stored total
player.potential_p2p  # Should be 1 if total > 1494
```

### Verification Logic Location

- **Total level check**: `app/models/player.rb` in `detailed_p2p_verification()` method
  - Check: `if overall > F2P_MAX_TOTAL`
- **P2P skill check**: `app/models/player.rb` in `detailed_p2p_verification()` method
  - Iterates through `MEMBERS_ONLY_SKILLS` checking for trained skills
- **Verification method**: `detailed_p2p_verification()` in Player model
- **Called by**: `check_p2p_stats()` method used by recheck task

## Questions?

If you have questions about:
- Why specific players are unavailable
- Whether to keep or remove unavailable players
- How to implement a custom cleanup policy

Please review the diagnostic output from `rake players:diagnose_high_total` first.
