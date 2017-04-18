class CreateMicrofinances < ActiveRecord::Migration[5.0]
  def change
  	create_table :microfinances do |t|
  		t.string :phoneNumber
  		t.string :name		
  		t.string :city
  		t.timestamps 
  	end
  	add_index :microfinances, :phoneNumber, unique:true  	
  end
end
