class CreateAccounts < ActiveRecord::Migration[5.0]
  def change
  	create_table :accounts do |t|
  		t.string :phoneNumber
  		t.decimal :balance
  		t.decimal :loan
  		t.timestamps 
  	end
  	add_index :accounts, :phoneNumber, unique:false	
  end
end
