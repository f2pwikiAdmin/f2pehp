namespace :players do
  desc "Fix nil sailing values by updating player stats from hiscores"
  task fix_sailing: :environment do
    players_with_nil_sailing = Player.where(sailing_lvl: nil).or(Player.where(sailing_xp: nil))
    total = players_with_nil_sailing.count

    puts "Found #{total} players with nil sailing values"
    puts "Starting updates..."

    players_with_nil_sailing.find_each.with_index do |player, index|
      begin
        player.update_player
        puts "[#{index + 1}/#{total}] Updated #{player.player_name}"
      rescue => e
        puts "[#{index + 1}/#{total}] Failed to update #{player.player_name}: #{e.message}"
      end

      # Sleep to avoid hitting API rate limits
      sleep 0.25 if (index + 1) % 10 == 0
    end

    puts "Done!"
  end
end
