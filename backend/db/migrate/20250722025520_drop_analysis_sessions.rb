class DropAnalysisSessions < ActiveRecord::Migration[8.0]
  def change
    drop_table :analysis_sessions
  end
end
