class AddBrutusKcToPlayers < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :brutus_kc, :int
    add_column :players, :brutus_kc_rank, :int
  end
end
