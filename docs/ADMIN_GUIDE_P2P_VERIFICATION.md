# Admin Guide: P2P Verification

## Overview

F2P.wiki now applies the same automatic P2P/F2P verification rules to every normal player during add and update operations.

## Current Rules

### Special-case lists
These still exist in `config/initializers/assets.rb`:
- `fakes` → always treated as P2P
- `false_banned` → always treated as F2P

### Normal players
Everyone not covered by those special lists goes through the same automatic checks:
1. Parser-detected P2P evidence (`potential_p2p > 0`)
2. Total level above the F2P maximum of 1494
3. Direct members-skill evidence (members-only skill level above 1 or XP above 0)

If any automatic check fails, the player is marked as P2P. If all pass, the player is treated as F2P.

## Removed Override List

The old `false_p2p_flagged` list has been removed from application config.

That means:
- there is no ranking override list to edit for false positives
- there is no `config.false_p2p_flagged` setting to maintain
- fixing false positives should happen in verification logic, not in a manual allowlist

Historical notes about that list now live in `docs/archive/FALSE_P2P_LIST_REMOVAL_SUMMARY.md` and `docs/archive/ARCHIVED_false_p2p_flagged_list.rb`.

## Activity-Based Detection Status

Automatic boss-KC and clue-scroll verification is currently disabled.

Why:
- OSRS hiscores activity ordering can change without notice
- position-based parsing created false positives
- the current mitigation prefers skills-based evidence until activity parsing is hardened

For the current mitigation details, see `docs/ACTIVITY_BASED_P2P_DETECTION_MITIGATION.md`.

## What to Monitor

### Application logs
Useful messages include:

```ruby
"Player #{name} passed detailed P2P verification - marked as F2P"
"Player #{name} marked as P2P: Parser detected P2P content (potential_p2p = X)"
"Player #{name} marked as P2P: Total level #{level} exceeds F2P max (1494)"
"Player #{name} marked as P2P: Has trained P2P skills (X levels beyond base)"
"Could not verify P2P hiscores content for #{name}: [error]"
```

### Rails console spot checks

```ruby
recent = Player.where("updated_at > ?", 1.hour.ago)
recent.each do |player|
  puts "#{player.player_name}: potential_p2p=#{player.potential_p2p}"
end
```

## Common Scenarios

### Player cannot add or update themselves
Likely causes:
- they really have P2P evidence
- upstream hiscores data changed in a way that exposed a verification edge case

Suggested steps:
1. Check logs for the exact failure reason.
2. Review the player on OSRS hiscores.
3. If the account is genuinely F2P, investigate the specific verification check that fired.

### Suspected false positive
Suggested steps:
1. Confirm the account is not in `fakes` and not genuinely P2P.
2. Inspect parser output and members-only skill values.
3. Review recent verification logs.
4. Fix the verification logic or parser behavior rather than reintroducing a manual override list.

### Want to audit verification quality
Suggested steps:
1. Review recent verification logs.
2. Sample players marked as P2P near the 1494 total-level threshold.
3. Use the manual analysis rake tasks below when deeper investigation is needed.

## Manual Analysis Tasks

These tasks are still useful for investigation even though activity-based checks are disabled in the automatic flow:

```bash
bundle exec rake players:check_false_p2p_flagged
bundle exec rake players:check_boss_kc
bundle exec rake players:check_clue_scrolls
bundle exec rake players:check_all_clue_scrolls
```

Treat their output as diagnostic input for review, not as a replacement for the current automatic rules.

## Best Practices

1. Prefer fixing verification logic over adding manual overrides.
2. Watch for upstream hiscores format changes.
3. Re-check borderline cases after parser changes.
4. Keep the archived docs in `docs/archive/` as historical context, not current procedure.

## Related Documentation

- `docs/P2P_VERIFICATION_UPDATE.md`
- `docs/P2P_DETECTION_FIX.md`
- `docs/ACTIVITY_BASED_P2P_DETECTION_MITIGATION.md`
- `docs/archive/FALSE_P2P_LIST_REMOVAL_SUMMARY.md`
