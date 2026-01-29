class AddHiscoresExtrasToPlayers < ActiveRecord::Migration[7.0]
  def change
    # Add a flexible column to store hiscores data that doesn't have dedicated columns
    # This allows the app to gracefully handle new OSRS activities without requiring
    # schema changes every time Jagex adds new content to the hiscores API
    add_column :players, :hiscores_extras, :text
  end
end
