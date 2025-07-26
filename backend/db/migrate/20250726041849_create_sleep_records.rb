class CreateSleepRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :sleep_records do |t|
      t.datetime :start_time, null: false      # 開始時刻
      t.datetime :end_time, null: false        # 終了時刻  
      t.integer :sleep_value, null: false      # 睡眠状態（0,1,2...）
      t.string :data_source                    # データソース
      t.decimal :duration_hours, precision: 4, scale: 2  # 継続時間（時間）
      
      t.timestamps
    end
    
    add_index :sleep_records, :start_time
    add_index :sleep_records, [:start_time, :end_time]
  end
end
