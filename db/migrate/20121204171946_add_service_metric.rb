class AddServiceMetric < ActiveRecord::Migration
  def up
    rename_table :applications, :v1_applications
    rename_table :half_hour_statuses, :v1_half_hour_statuses

    create_table :services do |t|
      t.string     :name,             :null => false
    end
    add_index :services, [ :name ], :unique => true

    create_table :applications do |t|
      t.integer    :service_id,       :null => false
      t.string     :name,             :null => false
    end
    add_index :applications, [ :service_id, :name ], :unique => true

    create_table :metrics do |t|
      t.integer    :application_id,   :null => false
      t.string     :name,             :null => false
      t.integer    :status,           :null => false
      t.datetime   :saved_at,         :null => false
    end
    add_index :metrics, [ :application_id, :name ], :unique => true

    create_table :half_hour_statuses do |t|
      t.integer    :metric_id,        :null => false
      t.integer    :status,           :null => false
      t.datetime   :datetime,         :null => false
      t.datetime   :saved_at,         :null => false
    end
    add_index :half_hour_statuses, [ :metric_id ]
  end

  def down
    drop_table :metrics
    drop_table :half_hour_statuses
    rename_table :v1_applications, :applications
    rename_table :v1_half_hour_statuses, :half_hour_statuses
  end
end
