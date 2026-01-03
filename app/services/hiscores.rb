require 'open-uri'
require 'json'

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
    'Sailing' => 'sailing',
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
    'PvP Arena - Rank' => 'p2p_minigame',
    'Soul Wars Zeal' => 'p2p_minigame',
    'Rifts closed' => 'p2p_minigame',
    'Colosseum Glory' => 'p2p_minigame',
    'Abyssal Sire' => 'p2p_minigame',
    'Alchemical Hydra' => 'p2p_minigame',
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
    'Skotizo' => 'p2p_minigame',
    'Sol Heredit' => 'p2p_minigame',
    'Spindel' => 'p2p_minigame',
    'Tempoross' => 'p2p_minigame',
    'The Gauntlet' => 'p2p_minigame',
    'The Corrupted Gauntlet' => 'p2p_minigame',
    'The Leviathan' => 'p2p_minigame',
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
    'Zalcano' => 'p2p_minigame',
    'Zulrah' => 'p2p_minigame'
  }.freeze

  class << self
    def fetch_stats_by_acc(player_name, account_type)
      stats_uri = api_url(account_type, player_name)
      res = fetch(stats_uri)
      if res
        begin
          data = JSON.parse(res)
          parsed_data = parse_stats(data)
          return parsed_data
        rescue JSON::ParserError => e
          Rails.logger.warn "Failed to parse JSON for #{player_name}: #{e.message}"
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
            data = JSON.parse(res)
            parsed_data = parse_stats(data)
            stats_mutex.synchronize { stats << [parsed_data, mode_idx] }
          rescue JSON::ParserError => e
            Rails.logger.warn "Failed to parse JSON for #{player_name} mode #{modes[mode_idx]}: #{e.message}"
            # Skip this mode on JSON parse failure
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
        "m=hiscore_oldschool#{path_suffix[account_type.to_sym]}/index_lite.json",
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

    # Parses JSON hiscores data using name-based skill lookups.
    # This approach is dynamic and reliable - it doesn't depend on array positions,
    # making it resilient to Jagex adding/reordering skills in the API response.
    #
    # @param data [Hash] JSON response from OSRS hiscores API with 'skills' array
    # @param restrict_fields [Array<String>] Optional list of internal skill names to parse
    # @return [Hash, false] Parsed stats hash or false if data is invalid
    def parse_stats(data, restrict_fields = [])
      stats = { potential_p2p: 0 }

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
      if Rails.env.development? || (Rails.logger && Rails.logger.level <= Logger::DEBUG)
        unmapped_skills = skill_map.keys - SKILL_NAME_MAP.keys
        if unmapped_skills.any?
          Rails.logger.info "Found unmapped skills in hiscores API: #{unmapped_skills.join(', ')}"
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
          # Check if this is a real P2P skill (not unranked)
          # Unranked means rank=-1, level=1, xp=0
          if rank != -1 || lvl > 1 || xp > 0
            stats[:potential_p2p] += xp
          end
        when 'p2p_minigame'
          # Check if this is a real P2P minigame (not unranked)
          if rank != -1 || lvl > 1 || xp > 0
            stats[:potential_p2p] += lvl
          end
        when 'sailing'
          # Store sailing stats for P2P detection in player model
          # Sailing is checked separately in check_p2p_stats method
          stats['sailing_lvl'] = lvl
          stats['sailing_xp'] = xp
          stats['sailing_rank'] = rank
        when 'lms'
          stats[:lms_score] = lvl
          stats[:lms_rank] = rank
        when 'obor_kc'
          stats[:obor_kc] = lvl
          stats[:obor_kc_rank] = rank
        when 'bryophyta_kc'
          stats[:bryo_kc] = lvl
          stats[:bryo_kc_rank] = rank
        when 'clues_all', 'clues_beginner'
          stats[internal_skill_name] = lvl
          stats["#{internal_skill_name}_rank"] = rank
        when 'hitpoints'
          stats["#{internal_skill_name}_lvl"] = [lvl, MIN_HITPOINTS_LEVEL].max
          stats["#{internal_skill_name}_xp"] = [xp, MIN_HITPOINTS_XP].max
        else
          # F2P skills
          stats["#{internal_skill_name}_lvl"] = lvl
          stats["#{internal_skill_name}_xp"] = xp
          stats["#{internal_skill_name}_rank"] = rank
        end
      end

      stats
    end
  end
end
