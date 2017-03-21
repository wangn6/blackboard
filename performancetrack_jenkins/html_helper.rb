require 'erb'
require 'ostruct'

module Utilities
	#This is to help build an html file
	class HtmlHelper
		@@base_path = File.dirname(File.absolute_path __FILE__)
		@@report_template = File.join( @@base_path,'report_template.html.erb')
		def initialize
			@results = []
			@template = (File.new @@report_template).read
			@erb = ERB.new @template
		end

		def add_result_for_test_plan test_plan, start_time, end_time, report_name, report_link
			result = @results.select {|r| r.test_plan == test_plan}
			if result != nil && result.count > 0
				result.first.report_names << report_name
				result.first.report_links << report_link
			else
				@results << OpenStruct.new({:test_plan => test_plan, :start_time => start_time, :end_time => end_time, :report_names => [report_name], :report_links => [report_link]})
			end
		end

		def generate_report report_file
			File.open(File.join(@@base_path, report_file), 'w'){ |file|
				file.write @erb.result(binding)
			}
		end 
	end
end

