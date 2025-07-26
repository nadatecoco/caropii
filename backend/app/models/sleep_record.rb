class SleepRecord < ApplicationRecord
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :sleep_value, presence: true, inclusion: { in: 0..10 }
  
  validate :end_time_after_start_time
  
  before_save :calculate_duration
  
  # 睡眠状態の定数定義
  SLEEP_VALUES = {
    in_bed: 0,
    asleep: 1,
    asleep_deep: 2,
    asleep_rem: 3,
    awake: 4
  }.freeze
  
  # 睡眠状態の日本語表示
  def sleep_state_name
    case sleep_value
    when 0
      "ベッドにいる"
    when 1
      "睡眠中"
    when 2
      "深い睡眠"
    when 3
      "REM睡眠"
    when 4
      "覚醒"
    else
      "不明"
    end
  end
  
  # 継続時間計算（時間単位）
  def calculate_duration_hours
    return 0 unless start_time && end_time
    (end_time - start_time) / 1.hour
  end
  
  private
  
  def end_time_after_start_time
    return unless start_time && end_time
    
    if end_time <= start_time
      errors.add(:end_time, "は開始時刻より後である必要があります")
    end
  end
  
  def calculate_duration
    self.duration_hours = calculate_duration_hours
  end
end