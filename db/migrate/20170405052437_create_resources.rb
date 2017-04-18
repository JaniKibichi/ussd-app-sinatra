class CreateResources < ActiveRecord::Migration[5.0]
  def change
  	create_table :resources do |t|
  		t.string :name, null: false, default:''
  		t.timestamps
  	end
  	add_index :resources, :name, unique: true
  end
end
