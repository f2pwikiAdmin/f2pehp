require 'net/http'

namespace :players do
  desc "Re-fetch fresh hiscores data for all players and call update_player to correct stored stats (e.g. boss KCs after parse_stats_csv fixes)"
  task refetch_all: :environment do
    sleep_time = ENV['SLEEP']&.to_f || 0.2
    start_id = ENV['START_ID']&.to_i
    limit = ENV['LIMIT']&.to_i
    progress_every = ENV['PROGRESS']&.to_i || 50

    scope = Player.all
    scope = scope.where('id >= ?', start_id) if start_id
    count_scope = limit ? scope.limit(limit) : scope

    total = count_scope.count
    processed_count = 0
    network_failures = 0
    error_count = 0
    last_id = nil

    puts "=" * 80
    puts "players:refetch_all - Re-fetch hiscores & call update_player for all players"
    puts "=" * 80
    puts "Total players to process: #{total}"
    puts "Sleep time between players: #{sleep_time}s"
    puts "Start ID: #{start_id || 'beginning'}"
    puts "Limit: #{limit || 'none'}"
    puts "=" * 80
    puts ""

    start_time = Time.now

    scope.find_each(batch_size: 100) do |player|
      begin
        player.update_player
      rescue SocketError, Net::ReadTimeout => e
        network_failures += 1
        Rails.logger.warn("refetch_all: network error for #{player.player_name} (##{player.id}): #{e.message}")
      rescue StandardError => e
        error_count += 1
        Rails.logger.warn("refetch_all: failed #{player.player_name} (##{player.id}): #{e.message}")
        puts "[#{processed_count + 1}/#{total}] ✗ Error for #{player.player_name} (ID: #{player.id}): #{e.message}"
      end

      processed_count += 1
      last_id = player.id

      if (processed_count % progress_every).zero?
        puts "[#{processed_count}/#{total}] Processed #{processed_count} players (last id=#{last_id})"
      end

      sleep sleep_time
      break if limit && processed_count >= limit
    end

    elapsed_time = Time.now - start_time

    puts ""
    puts "=" * 80
    puts "Summary"
    puts "=" * 80
    puts "Total processed: #{processed_count}"
    puts "Network failures: #{network_failures}"
    puts "Errors: #{error_count}"
    puts "Elapsed time: #{elapsed_time.round(2)}s"
    puts "Last id: #{last_id || 'none'}"
    puts "=" * 80
  end
end
