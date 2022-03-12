class AddTimecrowdUserIdToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :timecrowd_user_id, :string
  end
end
