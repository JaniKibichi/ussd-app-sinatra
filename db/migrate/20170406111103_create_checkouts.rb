class CreateCheckouts < ActiveRecord::Migration[5.0]
  def change
  	create_table :checkouts do |t|
  		t.string :phoneNumber
  		t.string :status
  		t.decimal :amount
  		t.timestamps 
  	end
  	add_index :checkouts, :phoneNumber, unique:false 	
  end
end
