require 'open-uri'

class Hiscores
  extend Base

  REG_MODE = %w[Reg].freeze
  IRONMAN_MODES = %w[UIM HCIM IM].freeze
  ALL_MODES = %w[UIM HCIM IM Reg].freeze

  # Hitpoints minimum values - all accounts start with level 10 and 1154 XP
  MIN_HITPOINTS_LEVEL = 10
  MIN_HITPOINTS_XP = 1154

  # Skill name mapping from OSRS JSON API to internal representation
  # This dynamic approach allows handling any skill/activity that Jagex adds
  # Maps: JSON API skill name => internal skill identifier
  # Special identifiers:
  #   - 'p2p': P2P-only skills (contribute to P2P detection via XP)
  #   - 'p2p_minigame': P2P-only activities (contribute to P2P detection via score/KC)
  #   - Specific names: F2P activities tracked individually (e.g., 'lms', 'obor_kc')
  SKILL_NAME_MAP = {
    'Overall' => 'overall',
    'Attack' => 'attack',
    'Defence' => 'defence',
    'Strength' => 'strength',
    'Hitpoints' => 'hitpoints',
    'Ranged' => 'ranged',
    'Prayer' => 'prayer',
    'Magic' => 'magic',
    'Cooking' => 'cooking',
    'Woodcutting' => 'woodcutting',
    'Fletching' => 'p2p',
    'Fishing' => 'fishing',
    'Firemaking' => 'firemaking',
    'Crafting' => 'crafting',
    'Smithing' => 'smithing',
    'Mining' => 'mining',
    'Herblore' => 'p2p',
    'Agility' => 'p2p',
    'Thieving' => 'p2p',
    'Slayer' => 'p2p',
    'Farming' => 'p2p',
    'Runecraft' => 'runecraft',
    'Hunter' => 'p2p',
    'Construction' => 'p2p',
    'Sailing' => 'p2p',
    'Grid Points' => 'temp_gamemode',  # Temporary game mode - may have F2P components
    'League Points' => 'temp_gamemode',  # Leagues have F2P content - do NOT flag as P2P
    'Deadman Points' => 'p2p_minigame',  # Deadman is members-only
    'Bounty Hunter - Hunter' => 'p2p_minigame',
    'Bounty Hunter - Rogue' => 'p2p_minigame',
    'Bounty Hunter (Legacy) - Hunter' => 'p2p_minigame',
    'Bounty Hunter (Legacy) - Rogue' => 'p2p_minigame',
    'Clue Scrolls (all)' => 'clues_all',
    'Clue Scrolls (beginner)' => 'clues_beginner',
    'Clue Scrolls (easy)' => 'p2p_minigame',
    'Clue Scrolls (medium)' => 'p2p_minigame',
    'Clue Scrolls (hard)' => 'p2p_minigame',
    'Clue Scrolls (elite)' => 'p2p_minigame',
    'Clue Scrolls (master)' => 'p2p_minigame',
    'LMS - Rank' => 'lms',
    'PvP Arena - Rank' => 'pvp_arena_rank',
    'Soul Wars Zeal' => 'p2p_minigame',
    'Rifts closed' => 'p2p_minigame',
    'Colosseum Glory' => 'p2p_minigame',
    'Collections Logged' => 'collections_logged',
    'Abyssal Sire' => 'p2p_minigame',
    'Alchemical Hydra' => 'p2p_minigame',
    'Amoxliatl' => 'p2p_minigame',
    'Araxxor' => 'p2p_minigame',
    'Artio' => 'p2p_minigame',
    'Barrows Chests' => 'p2p_minigame',
    'Bryophyta' => 'bryophyta_kc',
    'Callisto' => 'p2p_minigame',
    'Calvar\'ion' => 'p2p_minigame',
    'Cerberus' => 'p2p_minigame',
    'Chambers of Xeric' => 'p2p_minigame',
    'Chambers of Xeric: Challenge Mode' => 'p2p_minigame',
    'Chaos Elemental' => 'p2p_minigame',
    'Chaos Fanatic' => 'p2p_minigame',
    'Commander Zilyana' => 'p2p_minigame',
    'Corporeal Beast' => 'p2p_minigame',
    'Crazy Archaeologist' => 'p2p_minigame',
    'Dagannoth Prime' => 'p2p_minigame',
    'Dagannoth Rex' => 'p2p_minigame',
    'Dagannoth Supreme' => 'p2p_minigame',
    'Deranged Archaeologist' => 'p2p_minigame',
    'Doom of Mokhaiotl' => 'p2p_minigame',
    'Duke Sucellus' => 'p2p_minigame',
    'General Graardor' => 'p2p_minigame',
    'Giant Mole' => 'p2p_minigame',
    'Grotesque Guardians' => 'p2p_minigame',
    'Hespori' => 'p2p_minigame',
    'Kalphite Queen' => 'p2p_minigame',
    'King Black Dragon' => 'p2p_minigame',
    'Kraken' => 'p2p_minigame',
    'Kree\'Arra' => 'p2p_minigame',
    'K\'ril Tsutsaroth' => 'p2p_minigame',
    'Lunar Chests' => 'p2p_minigame',
    'Mimic' => 'p2p_minigame',
    'Nex' => 'p2p_minigame',
    'Nightmare' => 'p2p_minigame',
    'Phosani\'s Nightmare' => 'p2p_minigame',
    'Obor' => 'obor_kc',
    'Phantom Muspah' => 'p2p_minigame',
    'Sarachnis' => 'p2p_minigame',
    'Scorpia' => 'p2p_minigame',
    'Scurrius' => 'p2p_minigame',
    'Shellbane Gryphon' => 'p2p_minigame',
    'Skotizo' => 'p2p_minigame',
    'Sol Heredit' => 'p2p_minigame',
    'Spindel' => 'p2p_minigame',
    'Tempoross' => 'p2p_minigame',
    'The Gauntlet' => 'p2p_minigame',
    'The Corrupted Gauntlet' => 'p2p_minigame',
    'The Hueycoatl' => 'p2p_minigame',
    'The Leviathan' => 'p2p_minigame',
    'The Royal Titans' => 'p2p_minigame',
    'The Whisperer' => 'p2p_minigame',
    'Theatre of Blood' => 'p2p_minigame',
    'Theatre of Blood: Hard Mode' => 'p2p_minigame',
    'Thermy' => 'p2p_minigame',
    'Tombs of Amascut' => 'p2p_minigame',
    'Tombs of Amascut: Expert Mode' => 'p2p_minigame',
    'TzKal-Zuk' => 'p2p_minigame',
    'TzTok-Jad' => 'p2p_minigame',
    'Vardorvis' => 'p2p_minigame',
    'Venenatis' => 'p2p_minigame',
    'Vet\'ion' => 'p2p_minigame',
    'Vorkath' => 'p2p_minigame',
    'Wintertodt' => 'p2p_minigame',
    'Yama' => 'p2p_minigame',
    'Zalcano' => 'p2p_minigame',
    'Zulrah' => 'p2p_minigame'
  }.freeze

  class << self
    def fetch_stats_by_acc(player_name, account_type)
      stats_uri = api_url(account_type, player_name)
      res = fetch(stats_uri)
      if res
        begin
          parsed_data = parse_stats_csv(res)
          return parsed_data
        rescue => e
          Rails.logger.warn "Failed to parse hiscores data for #{player_name}: #{e.message}"
          return false
        end
      else
        return false
      end
    end

    def fetch_stats(player_name, account_type: nil)
      modes =
        if account_type
          # Retrieve a `modes` list of hierarchy to check total exps in order.
          # For UIM:  [UIM, IM, Reg]
          # For HCIM: [HCIM, IM, Reg]
          # For IM:   [IM, Reg]
          # For Reg:  [Reg]
          case account_type
          when *REG_MODE
            REG_MODE
          when *IRONMAN_MODES
            ancestors = Player.account_type_ancestors[account_type.to_sym]
            [account_type] + ancestors
          else
            raise ArgumentError, 'account type not recognized'
          end
        else
          ALL_MODES
        end

      stats = []
      threads = []
      stats_mutex = Mutex.new
      uri_per_mode = modes.map { |mode| api_url(mode, player_name) }

      uri_per_mode.each_with_index do |uri, mode_idx|
        threads << Thread.new(uri, mode_idx, stats) do |uri, mode_idx, stats|
          # Raise exceptions in main thread so they can be caught.
          Thread.current.abort_on_exception = true

          res = fetch(uri)

          # No hiscores data for this mode, skip.
          next unless res

          begin
            parsed_data = parse_stats_csv(res)
            stats_mutex.synchronize { stats << [parsed_data, mode_idx] }
          rescue => e
            Rails.logger.warn "Failed to parse hiscores data for #{player_name} mode #{modes[mode_idx]}: #{e.message}"
            # Skip this mode on parse failure
            next
          end
        end
      end

      threads.each(&:join)
      return if stats.empty?

      # Find the mode with the highest amount of total exp.
      actual_stats, mode_idx = stats.sort_by do |mode_stats_idx|
        mode_stats, idx = mode_stats_idx
        [-mode_stats['overall_xp'], idx]
      end.first

      [actual_stats, modes[mode_idx]]
    end

    def hcim_dead?(player_name)
      uri = table_url("hcim", player_name)

      begin
        content = fetch(uri)
      rescue SocketError, Net::ReadTimeout
        Rails.logger.warn "#{player_name}'s HCIM hiscores retrieval failed"
        return false
      end

      return false unless content

      page = Nokogiri::HTML(content)
      page.xpath('//*[@id="contentHiscores"]/table/tbody/tr[contains(@class, "--dead")]/td/a/span')
          .first
          .present?
    end

    def get_registered_player_name(account_type, player_name)
      uri = table_url(account_type, player_name)

      begin
        content = fetch(uri)
      rescue SocketError, Net::ReadTimeout
        Rails.logger.warn "#{player_name}'s hiscores retrieval failed"
        return false
      end

      page = Nokogiri::HTML(content)
      el = page.xpath('//*[@id="contentHiscores"]/table/tbody/tr/td/a/span')
               .first
      return el.inner_html.force_encoding('utf-8') if el
      return player_name # player is unranked for overall level

      false
    end

    private

    def url_friendly_name(player_name)
      ERB::Util.url_encode(player_name).gsub(/(%C2)*%A0/, '_')
    end

    def api_url(account_type, player_name)
      unless account_type.in? Player.account_types
        raise ArgumentError, 'account type not recognized'
      end

      path_suffix = {
        HCIM: '_hardcore_ironman',
        UIM: '_ultimate',
        IM: '_ironman'
      }

      URI.join(
        'https://secure.runescape.com',
        "m=hiscore_oldschool#{path_suffix[account_type.to_sym]}/index_lite.ws",
        "?player=#{url_friendly_name(player_name)}"
      )
    end

    def table_url(account_type, player_name)
      path = 'hiscore_oldschool'

      path_suffix = {
        HCIM: '_hardcore_ironman',
        UIM: '_ultimate',
        IM: '_ironman'
      }

      URI.join(
        'https://secure.runescape.com',
        "m=#{path}#{path_suffix[account_type.to_sym]}/overall.ws",
        "?user=#{url_friendly_name(player_name)}"
      )
    end

    # Parses CSV hiscores data from OSRS API.
    # The API returns newline-separated CSV values in a fixed order.
    # Each line contains: rank,level,xp for skills or rank,score for activities/bosses.
    #
    # IMPORTANT: Both F2P and P2P accounts return 25 skill lines (lines 0-24), including Sailing.
    # The presence of 25 skills does NOT indicate P2P membership.
    # P2P detection is based on whether any members-only skill shows training beyond default
    # (level > 1 or xp > 0). Unranked P2P skills at level 1 with 0 XP do NOT flag as P2P.
    #
    # @param csv_data [String] CSV response from OSRS hiscores API
    # @return [Hash, false] Parsed stats hash or false if data is invalid
    def parse_stats_csv(csv_data)
      return false unless csv_data && csv_data.is_a?(String)
      
      lines = csv_data.strip.split("\n")
      return false if lines.empty?
      
      stats = {
        "potential_p2p" => 0,
        
        # helpers for deterministic reconciliation in Player model
        f2p_levels_sum: 0,
        members_skill_count: 0,
        members_levels_sum: 0
      }
      
      # CSV line order matches this skill/activity order
      # Lines 0-24: Skills (Overall, Attack, Defence, ..., Construction, Sailing)
      # Lines 25+: Activities (Clue Scrolls, Bounty Hunter, LMS, Bosses, etc.)
      csv_skill_order = [
        'Overall', 'Attack', 'Defence', 'Strength', 'Hitpoints', 'Ranged', 'Prayer', 'Magic',
        'Cooking', 'Woodcutting', 'Fletching', 'Fishing', 'Firemaking', 'Crafting', 'Smithing',
        'Mining', 'Herblore', 'Agility', 'Thieving', 'Slayer', 'Farming', 'Runecraft', 'Hunter',
        'Construction', 'Sailing'
      ]
      
      # Activities and bosses order (after skills)
      # IMPORTANT: This array order MUST match the exact order returned by the OSRS hiscores API CSV.
      # Note: This structure may differ from config.skills which follows the CML API structure.
      # The SKILL_NAME_MAP links OSRS activity names to internal names used in config.skills.
      csv_activity_order = [
        'Grid Points', 'League Points', 'Deadman Points',
        'Bounty Hunter - Hunter', 'Bounty Hunter - Rogue', 'Bounty Hunter (Legacy) - Hunter',
        'Bounty Hunter (Legacy) - Rogue', 'Clue Scrolls (all)', 'Clue Scrolls (beginner)',
        'Clue Scrolls (easy)', 'Clue Scrolls (medium)', 'Clue Scrolls (hard)', 'Clue Scrolls (elite)',
        'Clue Scrolls (master)', 'LMS - Rank', 'PvP Arena - Rank', 'Soul Wars Zeal', 'Rifts closed',
        'Colosseum Glory', 'Collections Logged', 'Abyssal Sire', 'Alchemical Hydra', 'Amoxliatl',
        'Araxxor', 'Artio', 'Barrows Chests', 'Bryophyta', 'Callisto', 'Calvar\'ion', 'Cerberus',
        'Chambers of Xeric', 'Chambers of Xeric: Challenge Mode', 'Chaos Elemental', 'Chaos Fanatic',
        'Commander Zilyana', 'Corporeal Beast', 'Crazy Archaeologist', 'Dagannoth Prime', 'Dagannoth Rex',
        'Dagannoth Supreme', 'Deranged Archaeologist', 'Doom of Mokhaiotl', 'Duke Sucellus',
        'General Graardor', 'Giant Mole', 'Grotesque Guardians', 'Hespori', 'Kalphite Queen',
        'King Black Dragon', 'Kraken', 'Kree\'Arra', 'K\'ril Tsutsaroth', 'Lunar Chests', 'Mimic',
        'Nex', 'Nightmare', 'Phosani\'s Nightmare', 'Obor', 'Phantom Muspah', 'Sarachnis', 'Scorpia',
        'Scurrius', 'Shellbane Gryphon', 'Skotizo', 'Sol Heredit', 'Spindel', 'Tempoross',
        'The Gauntlet', 'The Corrupted Gauntlet', 'The Hueycoatl', 'The Leviathan', 'The Royal Titans',
        'The Whisperer', 'Theatre of Blood', 'Theatre of Blood: Hard Mode', 'Thermy',
        'Tombs of Amascut', 'Tombs of Amascut: Expert Mode', 'TzKal-Zuk', 'TzTok-Jad', 'Vardorvis',
        'Venenatis', 'Vet\'ion', 'Vorkath', 'Wintertodt', 'Yama', 'Zalcano', 'Zulrah'
      ]
      
      # Parse skills (first 25 lines)
      csv_skill_order.each_with_index do |skill_name, idx|
        next if idx >= lines.length
        
        line = lines[idx]
        values = line.split(',').map(&:strip).map(&:to_i)
        next if values.length < 3
        
        rank, lvl, xp = values[0], values[1], values[2]
        
        # Map to internal skill name using SKILL_NAME_MAP
        internal_skill_name = SKILL_NAME_MAP[skill_name]
        next unless internal_skill_name
        
        # Ensure non-negative values
        rank = [rank, -1].max
        lvl = [lvl, 1].max
        xp = [xp, 0].max
        
        # Process based on skill type
        case internal_skill_name
        when 'p2p'
          # Members-only skill (Fletching, Herblore, Agility, Thieving, Slayer, Farming, Hunter, Construction, Sailing)
          # IMPORTANT: Presence of these skills does NOT indicate P2P membership.
          # Only flag as P2P if the skill shows evidence of training beyond default (level > 1 OR xp > 0).
          # Unranked skills at level 1 with 0 XP (e.g., "-1,1,0") are NOT flagged as P2P.
          # Track counts for Player model's deterministic reconciliation
          stats[:members_skill_count] += 1
          stats[:members_levels_sum] += lvl
          if lvl > 1 || xp > 0
            stats["potential_p2p"] = 1
          end
        when 'hitpoints'
          stats["#{internal_skill_name}_lvl"] = [lvl, MIN_HITPOINTS_LEVEL].max
          stats["#{internal_skill_name}_xp"] = [xp, MIN_HITPOINTS_XP].max
          stats["#{internal_skill_name}_rank"] = rank
          stats[:f2p_levels_sum] += stats["#{internal_skill_name}_lvl"].to_i
        when 'overall'
          # Overall is the total level, not an individual skill
          # Store it but do NOT add it to f2p_levels_sum (would be double-counting)
          stats["#{internal_skill_name}_lvl"] = lvl
          stats["#{internal_skill_name}_xp"] = xp
          stats["#{internal_skill_name}_rank"] = rank
        else
          # F2P skills (store + include in f2p level sum)
          stats["#{internal_skill_name}_lvl"] = lvl
          stats["#{internal_skill_name}_xp"] = xp
          stats["#{internal_skill_name}_rank"] = rank
          stats[:f2p_levels_sum] += lvl
        end
      end
      
      # Parse activities and bosses (lines 25+)
      activity_start_idx = csv_skill_order.length
      csv_activity_order.each_with_index do |activity_name, idx|
        line_idx = activity_start_idx + idx
        next if line_idx >= lines.length
        
        line = lines[line_idx]
        values = line.split(',').map(&:strip).map(&:to_i)
        next if values.length < 2
        
        rank, score = values[0], values[1]
        
        # Map to internal activity name using SKILL_NAME_MAP
        internal_activity_name = SKILL_NAME_MAP[activity_name]
        next unless internal_activity_name
        
        # Ensure non-negative values
        rank = [rank, -1].max
        score = [score, 0].max
        
        # Process based on activity type
        case internal_activity_name
        when 'p2p_minigame'
          # Members activity/minigame detected => flag as P2P
          # Flag if score > 0 (indicates P2P activity participation)
          if score > 0
            stats["potential_p2p"] = 1
          end
        when 'temp_gamemode'
          # Temporary game mode (Leagues, Grid Points, etc.)
          # Do NOT flag as P2P - these can have F2P components
          # Just store the score for tracking but don't set potential_p2p
          # These are ignored in P2P detection
        when 'lms'
          # LMS is F2P
          stats[:lms_score] = score
          stats[:lms_rank] = rank
        when 'pvp_arena_rank'
          # PvP Arena - Rank is F2P (F2P players can participate)
          # Store as score/rank pair without flagging as P2P
          stats[:pvp_arena_rank_score] = score
          stats[:pvp_arena_rank_rank] = rank
        when 'collections_logged'
          # Collections Logged is F2P (F2P players can have collection log entries)
          # Store as score/rank pair without flagging as P2P
          stats[:collections_logged_score] = score
          stats[:collections_logged_rank] = rank
        when 'obor_kc'
          # F2P boss KC
          stats[:obor_kc] = score
          stats[:obor_kc_rank] = rank
        when 'bryophyta_kc'
          # F2P boss KC
          stats[:bryo_kc] = score
          stats[:bryo_kc_rank] = rank
        when 'clues_all', 'clues_beginner'
          # F2P clue scrolls: treat as score-like
          stats[internal_activity_name] = score
          stats["#{internal_activity_name}_rank"] = rank
        end
      end
      
      # Derive overall level if present in mapping (Overall should map to "overall")
      # If SKILL_NAME_MAP doesn't map "Overall" -> "overall", overall_lvl will remain 0.
      overall_lvl = stats["overall_lvl"].to_i
      stats[:overall_lvl] = overall_lvl

      # potential_p2p is now set as a boolean flag (0 or 1) in the case statements above
      # when any P2P skill or minigame is detected
      
      stats
    end

    # Parses JSON hiscores data using name-based skill lookups.
    # This approach is dynamic and reliable - it doesn't depend on array positions,
    # making it resilient to Jagex adding/reordering skills in the API response.
    #
    # IMPORTANT: Both F2P and P2P accounts have 25 skills, including Sailing.
    # The presence of these skills does NOT indicate P2P membership.
    # P2P detection is based on whether any members-only skill shows training beyond default
    # (level > 1 or xp > 0). Unranked P2P skills at level 1 with 0 XP do NOT flag as P2P.
    #
    # @param data [Hash] JSON response from OSRS hiscores API with 'skills' array
    # @param restrict_fields [Array<String>] Optional list of internal skill names to parse
    # @return [Hash, false] Parsed stats hash or false if data is invalid
    def parse_stats(data, restrict_fields = [])
      stats = {
        "potential_p2p" => 0,
        
        # helpers for deterministic reconciliation in Player model
        f2p_levels_sum: 0,
        members_skill_count: 0,
        members_levels_sum: 0
      }

      # Safety guard: ensure data has skills array
      unless data && data['skills'] && data['skills'].is_a?(Array)
        Rails.logger.warn "Invalid JSON hiscores data: missing or invalid 'skills' array"
        return false
      end

      # Build a skill map by name for efficient lookups
      # This makes parsing order-independent and resilient to API changes
      skill_map = {}
      data['skills'].each do |skill_data|
        skill_name = skill_data['name']
        skill_map[skill_name] = skill_data if skill_name
      end

      # Log any unmapped skills for future consideration (only in development/debug)
      # This helps identify when Jagex adds new content to the API
      if Rails.env.development?
        unmapped_skills = skill_map.keys - SKILL_NAME_MAP.keys
        if unmapped_skills.any?
          Rails.logger&.debug "Found unmapped skills in hiscores API: #{unmapped_skills.join(', ')}"
        end
      end

      # Process each skill from the JSON data using the skill name mapping
      skill_map.each do |json_skill_name, skill_data|
        # Use our internal mapping to convert JSON skill names
        internal_skill_name = SKILL_NAME_MAP[json_skill_name]
        
        # Skip skills not in our mapping (e.g., newly added activities we don't track yet)
        # This makes the parser forward-compatible with API additions
        next unless internal_skill_name

        # Skip if restrict_fields is provided and this skill is not in it
        if restrict_fields.any? && !restrict_fields.include?(internal_skill_name)
          next
        end

        rank = skill_data['rank'] || -1
        lvl = skill_data['level'] || 1
        xp = skill_data['xp'] || 0

        # Ensure non-negative values
        rank = [rank, -1].max
        lvl = [lvl, 1].max
        xp = [xp, 0].max

        case internal_skill_name
        when 'p2p'
          # Members-only skill (Fletching, Herblore, Agility, Thieving, Slayer, Farming, Hunter, Construction, Sailing)
          # IMPORTANT: Presence of these skills does NOT indicate P2P membership.
          # Only flag as P2P if the skill shows evidence of training beyond default (level > 1 OR xp > 0).
          # Unranked skills at level 1 with 0 XP are NOT flagged as P2P.
          # Track counts for Player model's deterministic reconciliation
          stats[:members_skill_count] += 1
          stats[:members_levels_sum] += lvl
          if lvl > 1 || xp > 0
            stats["potential_p2p"] = 1
          end
        when 'p2p_minigame'
          # Members activity/minigame detected => flag as P2P (do NOT accumulate)
          # Flag if score > 0 (indicates P2P activity participation)
          score = [(skill_data['score'] || 0).to_i, 0].max
          if score > 0
            stats["potential_p2p"] = 1
          end
        when 'temp_gamemode'
          # Temporary game mode (Leagues, Grid Points, etc.)
          # Do NOT flag as P2P - these can have F2P components
          # Just store the score for tracking but don't set potential_p2p
          # These are ignored in P2P detection
        when 'lms'
          # LMS is F2P
          score = [(skill_data['score'] || 0).to_i, 0].max
          stats[:lms_score] = score > 0 ? score : lvl
          stats[:lms_rank] = rank
        when 'pvp_arena_rank'
          # PvP Arena - Rank is F2P (F2P players can participate)
          # Store as score/rank pair without flagging as P2P
          score = [(skill_data['score'] || 0).to_i, 0].max
          stats[:pvp_arena_rank_score] = score > 0 ? score : lvl
          stats[:pvp_arena_rank_rank] = rank
        when 'collections_logged'
          # Collections Logged is F2P (F2P players can have collection log entries)
          # Store as score/rank pair without flagging as P2P
          score = [(skill_data['score'] || 0).to_i, 0].max
          stats[:collections_logged_score] = score > 0 ? score : lvl
          stats[:collections_logged_rank] = rank
        when 'obor_kc'
          # F2P boss KC
          score = [(skill_data['score'] || 0).to_i, 0].max
          stats[:obor_kc] = score > 0 ? score : lvl
          stats[:obor_kc_rank] = rank
        when 'bryophyta_kc'
          # F2P boss KC
          score = [(skill_data['score'] || 0).to_i, 0].max
          stats[:bryo_kc] = score > 0 ? score : lvl
          stats[:bryo_kc_rank] = rank
        when 'clues_all', 'clues_beginner'
          # F2P clue scrolls: treat as score-like
          score = [(skill_data['score'] || 0).to_i, 0].max
          v = score > 0 ? score : lvl
          stats[internal_skill_name] = v
          stats["#{internal_skill_name}_rank"] = rank
        when 'hitpoints'
          stats["#{internal_skill_name}_lvl"] = [lvl, MIN_HITPOINTS_LEVEL].max
          stats["#{internal_skill_name}_xp"] = [xp, MIN_HITPOINTS_XP].max
          stats["#{internal_skill_name}_rank"] = rank
          stats[:f2p_levels_sum] += stats["#{internal_skill_name}_lvl"].to_i
        when 'overall'
          # Overall is the total level, not an individual skill
          # Store it but do NOT add it to f2p_levels_sum (would be double-counting)
          stats["#{internal_skill_name}_lvl"] = lvl
          stats["#{internal_skill_name}_xp"] = xp
          stats["#{internal_skill_name}_rank"] = rank
        else
          # F2P skills (store + include in f2p level sum)
          stats["#{internal_skill_name}_lvl"] = lvl
          stats["#{internal_skill_name}_xp"] = xp
          stats["#{internal_skill_name}_rank"] = rank
          stats[:f2p_levels_sum] += lvl
        end
      end

      # Derive overall level if present in mapping (Overall should map to "overall")
      # If SKILL_NAME_MAP doesn't map "Overall" -> "overall", overall_lvl will remain 0.
      overall_lvl = stats["overall_lvl"].to_i
      stats[:overall_lvl] = overall_lvl

      # potential_p2p is now set as a boolean flag (0 or 1) in the case statements above
      # when any P2P skill or minigame is detected

      stats
    end
  end
end
