class CreateListings < ActiveRecord::Migration
  def change
    create_table :listings do |t|
      t.string :date_posted
      t.string :location
      t.string :photo_url
      t.string :description
      t.string :price
      t.integer :accommodates_num

      t.timestamps null: false
    end
  end
end
