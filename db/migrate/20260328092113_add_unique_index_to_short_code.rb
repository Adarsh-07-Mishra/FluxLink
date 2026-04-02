class AddUniqueIndexToShortCode < ActiveRecord::Migration[7.2]
  def change
    add_index :links, :short_code, unique: true
  end
end
