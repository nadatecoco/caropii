class CreateFoods < ActiveRecord::Migration[8.0]
  def change
    create_table :foods do |t|
      t.string :name
      t.decimal :protein
      t.decimal :fat
      t.decimal :carbs
      t.decimal :calories

      t.timestamps
    end
  end
end
