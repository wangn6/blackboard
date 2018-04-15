json.extract! test, :id, :task_name, :build_name, :class_name, :test_name, :create_time, :duration, :start_time, :end_time, :failure, :pass, :started, :created_at, :updated_at
json.url test_url(test, format: :json)
