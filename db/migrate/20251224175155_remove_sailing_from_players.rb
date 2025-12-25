class RemoveSailingFromPlayers < ActiveRecord::Migration[6.1]
  def change
    remove_column :players, :sailing_xp, :integer
    remove_column :players, :sailing_lvl, :integer
    remove_column :players, :sailing_ehp, :float
    remove_column :players, :sailing_rank, :integer

    remove_column :players, :sailing_xp_day_start, :integer
    remove_column :players, :sailing_xp_day_max, :integer
    remove_column :players, :sailing_ehp_day_start, :float
    remove_column :players, :sailing_ehp_day_max, :float

    remove_column :players, :sailing_xp_week_start, :integer
    remove_column :players, :sailing_xp_week_max, :integer
    remove_column :players, :sailing_ehp_week_start, :float
    remove_column :players, :sailing_ehp_week_max, :float

    remove_column :players, :sailing_xp_month_start, :integer
    remove_column :players, :sailing_xp_month_max, :integer
    remove_column :players, :sailing_ehp_month_start, :float
    remove_column :players, :sailing_ehp_month_max, :float

    remove_column :players, :sailing_xp_year_start, :integer
    remove_column :players, :sailing_xp_year_max, :integer
    remove_column :players, :sailing_ehp_year_start, :float
    remove_column :players, :sailing_ehp_year_max, :float
  end
end