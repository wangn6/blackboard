class CreateTests < ActiveRecord::Migration[5.1]
  def change
    create_table :tests do |t|
      t.text :task_name
      t.text :build_name
      t.text :class_name
      t.text :test_name
      t.date :create_time
      t.float :duration
      t.date :start_time
      t.date :end_time
      t.integer :failure
      t.integer :pass
      t.integer :started

      t.timestamps
    end
  end
end
