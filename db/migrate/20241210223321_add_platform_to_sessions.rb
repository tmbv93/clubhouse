class AddPlatformToSessions < ActiveRecord::Migration[8.0]
  def change
    add_reference :sessions, :platform, foreign_key: true
  end
end
