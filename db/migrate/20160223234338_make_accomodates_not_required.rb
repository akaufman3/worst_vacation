class MakeAccomodatesNotRequired < ActiveRecord::Migration
  def change
  	remove_column :listings, :accommodates_num, :integer
  	add_column :listings, :accommodates_num, :integer, null: true
  end
end
