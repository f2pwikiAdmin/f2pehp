# To Do List

List is in order of priority, with time estimates and the following tags.

* [BUGS] resolve unexpected site behavior
* [CALC] calculators
* [DATA] database and data storage
* [TEST] testing, QA
* [ALGO] algorithms, EHP, other backend
* [DVPS] devops and misc
* [FRNT] web development, frontend

## Backlog

* [FRNT] Display time until gains reset (15m)
* [DATA] Improve handling of or spread out Jagex API calls (8h)
  * perhaps this could allow for dynamic time tracking???
* [ALGO] Fix repair_records tool and records in general (8h)
* [FRNT] Link personal page skills to hiscores (2h)
* [DATA] Explore options to improve datapoint storage (12h)
* [FRNT] Latest 99 and 200ms (4h)
* [FRNT] Firsts to 99, 200ms (4h)
* [BUGS] Fix cache issues where users must use private mode to use site (2h)
* [FRNT] Create new pages to compare gains and records (2h)
* [FRNT] CSS color outlines for different account types (2h)
  * grey - irons, red - hc, white - uim
* [DVPS] Allow upload of content (flairs, news, etc) (24h)
  * Create admin user(s)?
* [CALC] Fix GP/XP calculator to update GE prices once per hour (2h)
* [CALC] Create general drop rate calculator (2h)
* [CALC] Create Ogress drops calculator (3h)
* [CALC] Create law usage calculator (3h)
* [ALGO] Create level 3 skiller EHP across Reg/IM/HC/UIM. (4h)
* [FRNT] Fix scrolls to not show small gaps (2h)
* [FRNT] Fix tables with long rows to not be cut off (1h)
* [FRNT] Fix names and flairs that spill to two lines long (1h)
* [FRNT] Clan affiliation for players, filtering by clan
* [FRNT] Competitions
* [FRNT] Improving front page to look more like classic OSRS front page with links

## In Progress

* [DVPS] Finish/verify Rails 7 upgrade on Ruby 3.2.3 (4h)
  * add and review `config.load_defaults 7.0` / `config/initializers/new_framework_defaults_7_0.rb`
  * resolve Rails 7 `legacy_connection_handling` boot deprecation
  * update the test schema for pending migration `20260228000000_add_brutus_kc_to_players` and rerun `bundle exec rspec`
* [DVPS] Debug Windows dev environment setup (4h)
* [TEST] Expand/backfill RSpec coverage across models/controllers/services/helpers/javascripts (24h)
  * fold loose one-off `test_*.rb`/diagnostic scripts into structured specs where worth keeping
* [DVPS] Refactor oversized config/initializers/assets.rb into smaller config sources (8h)
* [ALGO] Separate parsing + algorithm responsibilities out of Player model into services/modules (16h)
* [ALGO] Continue tuning P2P/F2P verification to reduce false positives (12h)
  * activity-based P2P checks are temporarily disabled due to unstable hiscores activity parsing
* [DATA] Continue periodic player cleanup/recheck workflows for potential_p2p flags (8h)

## Done

* [FRNT] FAQs page (8h)
* [DATA] Display players' ranks on F2P.wiki only (8h)
* [DATA] Add and display player created_at/updated_at timestamps (2h)
* [ALGO] Improve HC death, de-iron, and de-UIM detection (4h) - Mike
* [BUGS] When Jagex hiscores API is unresponsive, don't immediately mark as P2P (2h)
* [DATA] LMS ranks (2h)
* [FRNT] Consider restructuring Supporters list (2h) - Jack
* [CALC] Fix ranged DPS calculator to use correct attack speed (30m)
* [ALGO] Fix time-to-max to include bonus xp (4h)
  * Reg ttm should be <2400h
  * Sofacanlazy/Freckled Kid should have 0 ttm 99s
* [DVPS] Migrate off Heroku to Railway (PostgreSQL) (40h)
* [DVPS] Bump dependencies to Rails 7.0.4.3 on Ruby 3.2.3 (4h)
* [DATA] Remove deprecated columns from competitions (30m)
* [ALGO] Update Reg EHP from no-alt EHP to alt EHP. (2h)
* [ALGO] Update IM/HC/UIM EHP to use Ogress EHP. (40h)
* [ALGO] Implement Bonus XP algorithms (40h)
* [FRNT] Base level rankings (1h)
* [DVPS] Complete open sourcing (repo public + LICENSE) (8h)
* [ALGO] Ship universal 4-point P2P/F2P verification flow for new + existing players (16h)
* [DATA] Remove false_p2p_flagged override list from active ranking logic (8h)
* [DVPS] Reorganize root-level working docs/scripts into docs and archives (2h)
