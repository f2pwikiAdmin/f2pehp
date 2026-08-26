![F2P Wiki Banner Logo](app/assets/images/f2pwiki.png)

# F2P.wiki

F2P.wiki is an open source Old School RuneScape hiscores for Free-to-play players. 

## P2P Detection System

The application uses a robust P2P (members) detection system to ensure only F2P players are tracked. The system:

- **Parses all OSRS skills** from the hiscores API, including members-only skills (Fletching, Herblore, Agility, Thieving, Slayer, Farming, Hunter, Construction, Sailing)
- **Uses direct evidence checks** to determine P2P status: if ANY members-only skill has level > 1 OR xp > 0, the account is flagged as P2P
- **Handles skill list changes** gracefully without requiring code updates
- **Accurately identifies F2P players** at any total level up to the F2P maximum of 1494

For detailed information about the P2P detection logic and recent improvements, see [P2P_DETECTION_FIX.md](P2P_DETECTION_FIX.md).

## Contributing

We are happy to receive any and all help!

* Developers (Ruby, Rails, HTML/CSS/JavaScript)
* Open source experts
* Project owners
* Content managers (FAQs, links, etc.)

Feel free to look at our [TODO](TODO.md) list for any ideas.

To contribute a code change, please create a separate branch and submit a pull request.

## Install and setup

### 1. Install Git, Ruby, and Bundler

We recommend installing Ruby 3.2.3 as specified in the Gemfile.

#### Windows

* Git - [https://gitforwindows.org/](https://gitforwindows.org/)
* Ruby - [https://rubyinstaller.org/](https://rubyinstaller.org/)
* Bundler

```bash
gem install bundler
```

#### Mac

* Git - [https://sourceforge.net/projects/git-osx-installer/files/](https://sourceforge.net/projects/git-osx-installer/files/)
* Ruby - [http://railsinstaller.org/en](http://railsinstaller.org/en)
* Bundler

```bash
gem install bundler
```

#### Linux

Update the packages first using

```bash
sudo apt update
```

* Git

```bash
sudo apt-get install git
```

* Ruby

```bash
sudo apt install ruby-full
```

* Bundler

```bash
gem install bundler
```

### 2. Verify installation

```bash
git --version
```

```bash
ruby --version
```

```bash
bundler --version
```

### 3. Fork or clone the repository

```bash
git clone https://github.com/f2pwikiAdmin/f2pehp.git
```

Setting push origin to forked repo

```bash
git remote set-url origin --push https://github.com/USERNAME/f2pehp.git
```

### 4. Install ruby gems

```bash
bundle install
```

If bundler fails to install/locate pg, try installing `libpq-dev` first.

```
sudo apt-get install libpq-dev
```

### 5. Run database migrations

```bash
bundle exec rake db:migrate
```

### 6. Seed with dummy data

```bash
bundle exec rake db:seed
```

### 7. Verify installation by running server

```bash
rails s
```

The app should now be running at [http://localhost:3000](http://localhost:3000) or [127.0.0.1:3000](127.0.0.1:3000).

## Available Rake Tasks

### Full P2P Recheck

Performs a comprehensive P2P verification for all players by fetching fresh hiscores data and updating the `potential_p2p` flag using the existing model logic.

This task is useful for:
- Validating P2P status after logic updates
- Correcting false positives/negatives in bulk
- Periodic verification of player statuses

```bash
# Basic usage - process all players
bundle exec rake players:full_recheck_p2p

# Limit to 10 players for testing
bundle exec rake players:full_recheck_p2p LIMIT=10

# Start from a specific player ID
bundle exec rake players:full_recheck_p2p START_ID=1000

# Adjust sleep time between requests (default: 0.2 seconds)
bundle exec rake players:full_recheck_p2p SLEEP=0.5

# Combine options
bundle exec rake players:full_recheck_p2p START_ID=1000 LIMIT=100 SLEEP=0.3
```

**Environment Variables:**
- `LIMIT` - Maximum number of players to process
- `START_ID` - Start processing at/after this player ID
- `SLEEP` - Seconds to wait between players (default: 0.2)

**Note:** This task fetches live hiscores data for each player, so it may take considerable time for large player bases. The task is resilient to network errors and will continue processing if individual fetches fail.

### Check False P2P Flagged List

The application maintains a list of players incorrectly flagged as P2P (members) when they are actually F2P. These rake tasks help validate and maintain this list.

#### Check for P2P Skills

Checks if players in the false_p2p_flagged list have actually trained P2P skills (Fletching, Herblore, Agility, Thieving, Slayer, Farming, Hunter, Construction, Sailing):

```bash
bundle exec rake players:check_false_p2p_flagged
```

#### Check for P2P Boss KC

Checks if players in the false_p2p_flagged list have kill counts for P2P bosses (excluding F2P bosses Obor and Bryophyta):

```bash
bundle exec rake players:check_boss_kc
```

#### Check for P2P Clue Scrolls

Checks if players in the false_p2p_flagged list have completed P2P clue scrolls (excluding F2P beginner clues):

```bash
bundle exec rake players:check_clue_scrolls
```

#### Check All Players for P2P Clue Scrolls

Scans all players in the database (not just false_p2p_flagged list) to identify those who have completed P2P clue scrolls (easy, medium, hard, elite, or master). Players with only beginner clues and/or "clue scrolls (all)" are considered F2P.

```bash
bundle exec rake players:check_all_clue_scrolls
```

All of these tasks will output:
- Players who should be removed from the list (they have P2P evidence)
- Players not found in the database (may need cleanup)
- A summary with actionable recommendations

The false_p2p_flagged list can be edited in `config/initializers/assets.rb` (line 21).

## Useful Links

Rails Command Line - [https://guides.rubyonrails.org/command_line.html](https://guides.rubyonrails.org/command_line.html)

Bundler Commands - [https://bundler.io/v2.0/commands.html](https://bundler.io/v2.0/commands.html)

## License

MIT © F2P.wiki
