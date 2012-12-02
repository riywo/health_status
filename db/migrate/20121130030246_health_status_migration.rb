class HealthStatusMigration < ActiveRecord::Migration
  def up
    create_table :applications do |t|
      t.string     :name,             :null => false
      t.integer    :status,           :null => false
      t.datetime   :datetime,         :null => false
      t.datetime   :saved_at,         :null => false
    end
    add_index :applications, [ :name ], :unique => true

    create_table :half_hour_statuses do |t|
      t.integer    :application_id,   :null => false
      t.integer    :status,           :null => false
      t.datetime   :datetime,         :null => false
      t.datetime   :saved_at,         :null => false
    end
    add_index :half_hour_statuses, [:application_id]
  end

  def down
  end
end
