class AddUserReferenceToLinks < ActiveRecord::Migration[7.2]
  def change
    add_reference :links, :user, foreign_key: true, null: true
  end
end
