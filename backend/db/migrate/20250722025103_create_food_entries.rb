class CreateFoodEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :food_entries do |t|
      t.string :food_name
      t.decimal :protein
      t.decimal :fat
      t.decimal :carbs
      t.decimal :calories
      t.datetime :consumed_at

      t.timestamps
    end
  end
end
