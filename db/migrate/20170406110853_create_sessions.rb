class CreateSessions < ActiveRecord::Migration[5.0]
  def change
  	create_table :sessions do |t|
  		t.string :phoneNumber
  		t.string :sessionId
  		t.integer :level
  		t.timestamps 
  	end
  	add_index :sessions, :phoneNumber, unique:false
  end
end
