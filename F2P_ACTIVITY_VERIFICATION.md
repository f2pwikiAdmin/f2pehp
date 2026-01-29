# F2P Activity Verification Layer

## Overview
This document describes the additional verification layer added to the F2P player verification system for validating F2P-specific activities: boss kill counts (Obor and Bryophyta) and beginner clue scrolls.

## Purpose
The F2P activity verification layer provides an **additional positive signal** that helps confirm a player is truly F2P. It complements the existing skill-based verification but operates as a soft verification mechanism.

## Key Principles

### 1. Soft Verification (Positive Signal Only)
- **Presence of F2P activities = positive F2P signal** (logged for visibility)
- **Absence of F2P activities = neutral** (does NOT indicate P2P membership)
- **Missing/incomplete hiscores data = neutral** (does NOT block player)

### 2. Activities Verified
The verification checks ONLY these F2P-specific activities:
- **Obor KC** - F2P-only boss kill count
- **Bryophyta KC** - F2P-only boss kill count  
- **Beginner Clues** - F2P-only clue scroll tier

**Note:** No other boss KC or clue tiers are checked by this layer.

### 3. Design Goals
- **Visibility**: All verification decisions are logged for admins/users to understand
- **No false positives**: Missing data never incorrectly classifies a player as P2P
- **Soft gating**: Provides additional confidence but doesn't hard-block players
- **Complementary**: Works alongside existing skill-based verification

## Implementation

### Methods Added

#### Instance Method: `check_f2p_activity_signals(stats)`
Located in `app/models/player.rb`

Called during player updates to check and log F2P activity signals.

**Parameters:**
- `stats` (Hash): Stats hash from hiscores parser containing activity data

**Behavior:**
- Checks `obor_kc`, `bryo_kc`, and `clues_beginner` values from stats
- Logs any positive values as F2P verification signals
- Logs absence as acceptable (doesn't require these activities)
- Does NOT affect `potential_p2p` flag - purely informational

**Example Logs:**
```
Player TestPlayer F2P activity verification signals: Obor KC: 50, Bryophyta KC: 25, Beginner clues: 15
Player TestPlayer has no F2P boss KC or beginner clues (acceptable - not required for F2P verification)
```

#### Class Method: `check_initial_f2p_activity_signals(stats, name)`
Located in `app/models/player.rb`

Called during initial player creation to check and log F2P activity signals.

**Parameters:**
- `stats` (Hash): Stats hash from hiscores parser
- `name` (String): Player name for logging

**Behavior:**
- Same as instance method but operates during player creation workflow
- Called from `initial_detailed_p2p_check` before player object exists

### Integration Points

#### 1. Player Updates (`detailed_p2p_verification`)
Called when updating existing players via `check_p2p_stats`:
```ruby
# After all P2P checks, before returning false (F2P)
check_f2p_activity_signals(stats)
```

#### 2. Player Creation (`initial_detailed_p2p_check`)
Called when creating new players via `Player.create_new`:
```ruby
# After all P2P checks, before returning false (allow creation)
check_initial_f2p_activity_signals(stats, name)
```

## Database Schema

The following columns already exist in the `players` table:
- `obor_kc` (integer) - Obor kill count
- `obor_kc_rank` (integer) - Obor hiscores rank
- `bryo_kc` (integer) - Bryophyta kill count
- `bryo_kc_rank` (integer) - Bryophyta hiscores rank
- `clues_beginner` (integer) - Beginner clue count
- `clues_beginner_rank` (integer) - Beginner clue hiscores rank

No database migrations are required.

## Data Flow

### Hiscores Parser (`app/services/hiscores.rb`)
1. OSRS API returns boss KC and clue data
2. Parser maps to internal names:
   - `'Obor'` → `obor_kc`
   - `'Bryophyta'` → `bryophyta_kc` (internal) → stored as `bryo_kc`
   - `'Clue Scrolls (beginner)'` → `clues_beginner`
3. Stats hash includes these fields with symbol keys: `:obor_kc`, `:bryo_kc`, `:clues_beginner`

### Player Model (`app/models/player.rb`)
1. Receives stats hash from hiscores parser
2. Runs P2P verification checks (skills-based)
3. **NEW:** Runs F2P activity verification (logs positive signals)
4. Stores data in database columns
5. Updates `potential_p2p` based on P2P checks only (not F2P activities)

## Test Coverage

Test file: `spec/models/player_f2p_activity_verification_spec.rb`

### Scenarios Covered

#### 1. Player with Boss KC Present
- ✅ Logs Obor KC as positive signal
- ✅ Logs Bryophyta KC as positive signal
- ✅ Logs both when present
- ✅ Does NOT flag as P2P

#### 2. Player with Beginner Clues Present
- ✅ Logs beginner clues as positive signal
- ✅ Logs all activities when multiple present
- ✅ Does NOT flag as P2P

#### 3. Player with No F2P Activities
- ✅ Logs absence as acceptable
- ✅ Does NOT flag as P2P
- ✅ Missing fields treated as zero

#### 4. Hiscores Unavailable/Partial Response
- ✅ Incomplete data does NOT block player
- ✅ Nil values treated as zero
- ✅ Missing fields do NOT cause errors
- ✅ Does NOT flag as P2P

#### 5. Initial Player Creation
- ✅ Logs activities during creation workflow
- ✅ Allows creation with activities present
- ✅ Allows creation with no activities

### Running Tests

```bash
# Run all F2P activity verification tests
bundle exec rspec spec/models/player_f2p_activity_verification_spec.rb

# Run specific test context
bundle exec rspec spec/models/player_f2p_activity_verification_spec.rb:12

# Run all player P2P detection tests (includes existing tests)
bundle exec rspec spec/models/player_p2p_detection_spec.rb
```

## Verification Flow

### Add Player Flow (`/ranks` → "Add Player")
1. User submits player name
2. `PlayersController#create_player_if_needed` calls `Player.create_new(name)`
3. Fetches stats from OSRS hiscores
4. Runs `initial_p2p_check` which calls `initial_detailed_p2p_check`
5. **NEW:** Logs F2P activity signals via `check_initial_f2p_activity_signals`
6. If P2P detected → reject with "not a free to play account" message
7. If F2P → create player and redirect to player page

### Player Refresh/Update Flow
1. Background job or manual refresh triggers `update_player`
2. Fetches latest stats from OSRS hiscores
3. Calls `check_p2p_stats` which calls `detailed_p2p_verification`
4. **NEW:** Logs F2P activity signals via `check_f2p_activity_signals`
5. Updates `potential_p2p` flag based on P2P checks
6. Saves updated stats to database

## Logging Examples

### Successful F2P Verification with Activities
```
Player Dirtcrab F2P activity verification signals: Obor KC: 127, Bryophyta KC: 45, Beginner clues: 23
Player Dirtcrab passed detailed P2P verification - marked as F2P
```

### Successful F2P Verification without Activities
```
Player TestPlayer has no F2P boss KC or beginner clues (acceptable - not required for F2P verification)
Player TestPlayer passed detailed P2P verification - marked as F2P
```

### During Player Creation
```
Player NewPlayer F2P activity verification signals (creation): Obor KC: 10
Player NewPlayer passed detailed P2P verification (creation) - allowing creation as F2P
```

## Failure Modes and Handling

### Missing Hiscores Data
**Scenario:** OSRS API doesn't return boss KC or clue data

**Handling:**
- Fields will be nil or missing from stats hash
- `.to_i` converts nil → 0
- Zero values are not logged as signals
- Logs: "has no F2P boss KC or beginner clues (acceptable...)"
- Result: Player NOT flagged as P2P (soft verification)

### Partial Hiscores Response
**Scenario:** Only some fields are present in hiscores

**Handling:**
- Available fields are processed normally
- Missing fields treated as nil → 0
- Only present activities are logged
- Result: Player NOT flagged as P2P

### Hiscores API Completely Unavailable
**Scenario:** API returns error/timeout

**Handling:**
- Handled by existing `fetch_stats` error handling
- If stats can't be fetched, player creation/update fails upstream
- This verification layer never runs
- Result: Player creation/update returns 'failed' status

### Zero Values vs Missing Values
Both are treated identically (neutral signal):
- `obor_kc: 0` → not logged, acceptable
- `obor_kc: nil` → converts to 0, not logged, acceptable
- No `obor_kc` key → nil → converts to 0, not logged, acceptable

## Configuration

No configuration required. The verification layer uses:
- Existing database columns
- Existing hiscores parser mappings  
- Existing P2P detection constants (`P2P_BOSSES`, `P2P_CLUE_SCROLLS`)

The F2P bosses and clues are already correctly excluded from P2P detection lists in `app/models/player.rb`:
- `P2P_BOSSES` does NOT include Obor or Bryophyta
- `P2P_CLUE_SCROLLS` does NOT include beginner clues

## Future Enhancements

Potential improvements (not implemented):
1. **Admin Dashboard**: Display F2P activity counts in player profiles
2. **Aggregate Stats**: Track overall F2P boss KC/clue distribution
3. **Thresholds**: Alert on unusual patterns (e.g., very high KC for suspected P2P)
4. **Historical Tracking**: Compare activity changes over time

## Maintenance Notes

### Adding New F2P Activities
If Jagex adds new F2P-only activities to the game:

1. Add to hiscores parser `SKILL_NAME_MAP` in `app/services/hiscores.rb`
2. Add database migration for new columns
3. Add to `check_f2p_activity_signals` method
4. Add tests for the new activity

### Modifying Verification Logic
If verification logic needs to change:

1. Update `check_f2p_activity_signals` in `app/models/player.rb`
2. Update tests in `spec/models/player_f2p_activity_verification_spec.rb`
3. Update this documentation
4. Test with real player data before deploying

## References

- **Player Model**: `/app/models/player.rb`
- **Hiscores Service**: `/app/services/hiscores.rb`
- **Controller**: `/app/controllers/players_controller.rb`
- **Tests**: `/spec/models/player_f2p_activity_verification_spec.rb`
- **Existing P2P Tests**: `/spec/models/player_p2p_detection_spec.rb`

## Related Documentation

- `PLAYER_ADDITION_VERIFICATION.md` - Overall verification system documentation
- `P2P_VERIFICATION_UPDATE.md` - P2P verification changes
- `ADMIN_GUIDE_P2P_VERIFICATION.md` - Admin guide for P2P verification
