class RemoveDatetime < ActiveRecord::Migration
  def up
    remove_column(:applications, :datetime)
  end

  def down
    add_column(:applications, :datetime, :datetime, { :null => false })
  end
end
