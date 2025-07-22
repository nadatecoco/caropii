class CreateAnalysisSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :analysis_sessions do |t|
      t.text :session_data
      t.text :analysis_result

      t.timestamps
    end
  end
end
