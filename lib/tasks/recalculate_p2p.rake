namespace :players do
  desc "Recalculate potential_p2p flag for all players with updated sailing logic"
  task recalculate_p2p: :environment do
    total = Player.count
    updated_count = 0

    puts "Recalculating potential_p2p for #{total} players..."

    Player.find_each.with_index do |player, index|
      old_value = player.potential_p2p

      # Build stats hash from current player attributes
      

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
