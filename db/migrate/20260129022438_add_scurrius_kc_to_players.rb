class AddScurriusKcToPlayers < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :scurrius_kc, :int
    add_column :players, :scurrius_kc_rank, :int
  end
end
