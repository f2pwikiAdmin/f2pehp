namespace :players do
  desc "Update CML records for all active players with sailing data"
  task update_cml_records: :environment do
    players = Player.where("overall_ehp > 250 OR player_name IN #{Player.sql_supporters}")
    total = players.count
    updated_count = 0
    failed_count = 0

    puts "Updating CML records for #{total} players..."
    puts "This will fetch records from CrystalMathLabs API"

    players.find_in_batches(batch_size: 25).with_index do |batch, batch_index|
      batch.each.with_index do |player, index|
        overall_index = batch_index * 25 + index + 1

        begin
          player.repair_records
          updated_count += 1
          puts "[#{overall_index}/#{total}] Updated #{player.player_name}"
        rescue => e
          failed_count += 1
          puts "[#{overall_index}/#{total}] Failed to update #{player.player_name}: #{e.message}"
        end

        # Sleep to avoid hitting API rate limits
        sleep 0.25
      end

      # Longer sleep between batches
      sleep 1 unless batch_index == (total / 25.0).ceil - 1
    end

    puts "\nDone!"
    puts "Successfully updated: #{updated_count}"
    puts "Failed: #{failed_count}"
    puts "Total: #{total}"
  end
end
