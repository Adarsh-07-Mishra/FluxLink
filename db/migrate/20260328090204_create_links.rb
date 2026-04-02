class CreateLinks < ActiveRecord::Migration[7.2]
  def change
    create_table :links do |t|
      t.text :original_url
      t.string :short_code
      t.integer :clicks
      t.datetime :expires_at
      t.string :password_digest

      t.timestamps
    end
  end
end
