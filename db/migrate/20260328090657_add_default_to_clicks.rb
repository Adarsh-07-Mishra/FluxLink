class AddDefaultToClicks < ActiveRecord::Migration[7.2]
  def change
    change_column_default :links, :clicks, 0
  end
end
