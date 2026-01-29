namespace :players do
  desc "Recalculate potential_p2p flag for all players with updated sailing logic"
  task recalculate_p2p: :environment do
    total = Player.count
    updated_count = 0

    puts "Recalculating potential_p2p for #{total} players..."

    Player.find_each.with_index do |player, index|
      old_value = player.potential_p2p

      # Build stats hash from current player attributes
      stats = {}
      Player::SKILLS.each do |skill|
        stats["#{skill}_lvl"] = player.read_attribute("#{skill}_lvl")
        stats["#{skill}_xp"] = player.read_attribute("#{skill}_xp")
        stats["#{skill}_rank"] = player.read_attribute("#{skill}_rank")
      end
      # Note: Helper fields (f2p_levels_sum, members_skill_count, members_levels_sum) are not included
      # The verification logic will skip Check 1b when these are missing, which is correct behavior

      # Call the p2p check method with current player stats
      player.check_p2p_stats(stats)

      if old_value != player.potential_p2p
        updated_count += 1
        puts "[#{index + 1}/#{total}] Updated #{player.player_name}: #{old_value} -> #{player.potential_p2p}"
      elsif (index + 1) % 100 == 0
        puts "[#{index + 1}/#{total}] #{player.player_name}: Processed..."
      end
    end

    puts "Done! Updated #{updated_count} players out of #{total}"
  end
end
