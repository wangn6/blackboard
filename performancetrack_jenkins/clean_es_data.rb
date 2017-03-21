require 'rest-client'
require 'date'
require 'json'

module Utilities
	class ESDateCleaningHelper
		@@es_server = "http://performance-tracker-qa.mobile.medu.com:9200"
		@@index_type = ''
		@@server = RestClient::Resource.new(@@es_server)

		def initialize

		end

		def clean_jmeter_data_4_run run_id

		end

		def clean_jmeter_date_before end_time
			clean_jmeter_data_between(end_time << 6, end_time)
		end

		def clean_jmeter_data_between start_time, end_time
			date_to_delete = start_time
			while date_to_delete < end_time do 
				index_to_delete = get_index_name_for_date(date_to_delete)
				@@server["#{@@index_type}/#{index_to_delete}"].delete
				date_to_delete = date_to_delete + 1
			end
			@@server[get_index_name_for_date]
		end

		def clean_beat_data_before end_time

		end

		def clean_beat_data_between start_time, end_time

		end

		def get_index_name_for_date date_time
			time_string = date_time.to_time.utc.strftime("%Y.%m.%dT")
			"jmeter-elasticsearch-#{time_string}"
		end

	end
	
end