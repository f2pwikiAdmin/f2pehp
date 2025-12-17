class AddSailingToPlayers < ActiveRecord::Migration[6.1]
  def change
    # Basic sailing stats
    add_column :players, :sailing_xp, :integer
    add_column :players, :sailing_lvl, :integer
    add_column :players, :sailing_ehp, :float
    add_column :players, :sailing_rank, :integer

    # Daily tracking
    add_column :players, :sailing_xp_day_start, :integer
    add_column :players, :sailing_xp_day_max, :integer
    add_column :players, :sailing_ehp_day_start, :float
    add_column :players, :sailing_ehp_day_max, :float

    # Weekly tracking
    add_column :players, :sailing_xp_week_start, :integer
    add_column :players, :sailing_xp_week_max, :integer
    add_column :players, :sailing_ehp_week_start, :float
    add_column :players, :sailing_ehp_week_max, :float

    # Monthly tracking
    add_column :players, :sailing_xp_month_start, :integer
    add_column :players, :sailing_xp_month_max, :integer
    add_column :players, :sailing_ehp_month_start, :float
    add_column :players, :sailing_ehp_month_max, :float

    # Yearly tracking
    add_column :players, :sailing_xp_year_start, :integer
    add_column :players, :sailing_xp_year_max, :integer
    add_column :players, :sailing_ehp_year_start, :float
    add_column :players, :sailing_ehp_year_max, :float
  end
end
