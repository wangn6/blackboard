require 'rubygems'
require 'json'
require 'nokogiri'
require 'fileutils'
require 'securerandom'
require_relative 'zip_helper.rb'
require_relative 'file_helper.rb'
require_relative 'jmeter_helper.rb'
require_relative 'kibana_helper.rb'
require_relative 'html_helper.rb'
require_relative 'jmx_helper.rb'
require_relative 'elasticsearch_helper.rb'

module Utilities
	class ExecutionEngine
		@@default_start_threads = 20
		@@default_increase_steps = 10
		@@default_maximum_threads = 1000
		@@default_loops = 100

		def initialize start_num_threads, increase_step, target_num_threads, test_plan_template, loops, duration, warmup_period, environment, project
			
			#check whether the test plan is setup
			if (test_plan_template == nil)
				puts "Please specify the test plan to run"
				puts "Usage:"
				puts "----------------------------------"
				puts "export Test_Plan=my_testplan.jmx"
				puts "export Start_Num_Threads=4#optional"
				puts "export Increase_Step=2#optional"
				puts "export Target_Num_Threads=6#optional"
				puts "export Loops=100#optional"
				puts "export Warmup_Period=10#optional"
				puts "ruby #{__FILE__}"
				puts "----------------------------------"
				exit
			end
			#check the parameters
			if(start_num_threads == nil)
				#run the default jmx file
			elsif(start_num_threads % 2 == 1)
				raise "The start num threads must be even, because there're two JMeter Servers totally."
			elsif(increase_step == nil)
				raise "Please specify the increase step"
			elsif(increase_step < 2 || increase_step % 2 == 1)
				raise "The increase step must be positive and even, because there're two JMeter Servers totally. Detailed information please goto neil.wang@blackboard.com"
			elsif(target_num_threads == nil)
			      	raise "Please specify the target num threads"
			elsif(target_num_threads < start_num_threads)
				raise "The target num threads must be larger than the start num threads"
			end
			@start_num_threads = start_num_threads
			@increase_step = increase_step
			@target_num_threads = target_num_threads
			@test_plan_template = test_plan_template
			@loops = loops
			@duration = duration
			@warmup_period = warmup_period
			@project = project
			@environment = environment
			@test_plans_path = "#{ Time.now.strftime("%Y%m%d%H%M%S") }"
			@result_path = 'results_'
			@test_detailed_info = {
				'parameters'=>{
					'Start Threads' => start_num_threads,
					'Increase Step' => increase_step,
					'Target Threads' => target_num_threads,
					'Loops' => loops,
					'Rampup Period' => warmup_period,
					'Duration' => duration,
					'Test Environment' => project
				}
			}

			#the report helper to generate the report html
			@report_helper = Utilities::HtmlHelper.new
		end
		
		def ExecutionEngine.run_load_testing threads, test_plan, duration, warmup_period, environment, project
			prepare_before_execution
			execution_engine = ExecutionEngine.new threads, 2, threads, test_plan, nil, duration, warmup_period, environment, project
			execution_engine.run_test
			execution_engine.generate_test_report
			teardown_after_execution
		end

		def ExecutionEngine.run_spike_testing threads, test_plan, warmup_period, environment, project
			prepare_before_execution
			execution_engine = ExecutionEngine.new threads, 2, threads, test_plan, nil, warmup_period * 2, warmup_period, environment, project
			execution_engine.run_test
			execution_engine.generate_test_report
			teardown_after_execution
		end

		def ExecutionEngine.run_stress_testing test_plan, target_maximum_error_rate, target_avg_response_time, environment, project
			
			prepare_before_execution
			threads = @@default_start_threads
			while(threads < @@default_maximum_threads)
				execution_engine = ExecutionEngine.new @@default_start_threads, @@default_increase_steps, @@default_maximum_threads, test_plan, nil, warmup_period * 2, warmup_period, environment, project
				execution_engine.run_test
				run_id = execution_engine.get_run_id
				apis = Utilities::ElasticSearchHelper.search_unique_sample_labels run_id
				apis.each do |api|
					error_rate = Utilities::ElasticSearchHelper.get_error_rate run_id, threads, api
					avg_response_time = Utilities::ElasticSearchHelper.get_average_response_time run_id, threads, api
					if(error_rate > target_maximum_error_rate || avg_response_time > target_avg_response_time)
						puts "It has reach our criteria for api #{api} on threads #{threads}"
						puts "#{api}: Error Rate:#{error_rate}; Average Response Time: #{avg_response_time}"
						#TODO, create the report for the stress testing here
						#===========================================================
						threads = @@default_maximum_threads
					end
				end
				threads += @@default_increase_steps
			end
			execution_engine.generate_test_report
			teardown_after_execution

		end

		def ExecutionEngine.run_performance_test test_plan, project, environment
			prepare_before_execution
			testplan_template, threads, warmup_period, loops, duration
			new_test_plan = JMXHelper.generate_testplan test_plan, 2, 2, @@default_loops, 0
			JMXHelper.run_testplan new_test_plan
			execution_engine.run_test
			execution_engine.generate_test_report
			teardown_after_execution
		end

		def puts_execution_parameters
			#log the input parameters
			puts "Parameters:"
			puts "-------------------------------"
			puts "Start Num Threads: #{@start_num_threads}"
			puts "Increase Step: #{@increase_step}"
			puts "Target Num Threads: #{@target_num_threads}"
			puts "Test Plan/Package: #{@test_plan_template}"
			puts "Loops: #{@loops}"
			puts "Duration: #{@duration}"
			puts "Warmup Period:#{@warmup_period}"
			puts "Test Environment:#{@environment}"
			puts "-------------------------------"
		end

		#get all the test plans within the package
		def get_all_test_plans_within_package
			testplanTemplates = []
			Dir.mkdir(@test_plans_path, 0777)
			

			test_plan_template = File.join(@test_plans_path, @test_plan_template)
			FileUtils.mv("Test_Plan", test_plan_template)
			if(File.extname(test_plan_template) == '.zip')
				Utilities::ZipHelper.unzip(test_plan_template, File.dirname(test_plan_template))
				#copy the files within the folder into the current folder
				Dir.foreach(File.dirname(test_plan_template)) do |item|
			                if(item == '.' || item == '..')
						break
					else
						folder_item = File.join(File.dirname(test_plan_template), item)
			                	if(File.directory?(folder_item))
			                        	Utilities::FileHelper.move_folder_content(folder_item, File.dirname(test_plan_template))
			                	end
						end
			        end
				#find the test plans within the current folder
				Dir.foreach(File.dirname(test_plan_template)) do |item|
					file_item = File.join(File.dirname(test_plan_template), item)
					if(File.file?(file_item) && File.extname(file_item) == '.jmx')
						testplanTemplates << file_item
					end
				end
				if(testplanTemplates == nil || testplanTemplates.size == 0)
					raise "Could not find any valid test plan file within the zip package"
				end
			elsif(File.extname(test_plan_template) == '.jmx')
				testplanTemplates << test_plan_template
			else
				raise "Could not support the test plan format of #{test_plan_template} now, only support the .jmx or the .zip format."
			end
			puts "There are totally #{testplanTemplates.length} test plans within the package to run"
			testplanTemplates
		end

		def prepare_before_execution
			#Save the test plan package which will be saved into the ES
			ENV["PT_test_plan_package"] = @test_plan_template

			@testplanTemplates = get_all_test_plans_within_package
			#Generate the RunID which will be used to group all the sample result in an easy way
			@run_id = SecureRandom.uuid
			ENV["PT_RunId"] = @run_id
			puts "The run Id is: "
			puts "-------------------------------"
			puts "RunId:#{@run_id}"
			puts "-------------------------------"
			puts "This id can be used to query the sample results from Kibana http://performance-tracker-qa.mobile.medu.com:5601/" 

			FileUtils.rm_rf(@result_path)
			#Prepare for the execution
			Utilities::JMeterHelper.clear_test_data_folder
			Utilities::JMeterHelper.start_remote_servers

			#Start to run the test plans
			puts "-------------------------------"
			@start_time = DateTime.now
			puts "Start From: #{@start_time}"
			puts "-------------------------------"

		end
		
		def run_test 

			puts "Start to run the test plan #{@test_plan_template}"

			template = File.basename @test_plan_template

			#TODO, Currently the project is set to planner-qa by dafault, this setting is used to filter the beat logs for the servers
			@kibana_helper = Utilities::KibanaHelper.new template, @run_id,  @project
			
			@kibana_helper.start

			monitoring_url = @kibana_helper.generate_realtime_dashboard

			puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
			puts "You can monitor the realtime execution at Kibana from:"
			puts "#{monitoring_url}"
			puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

			ENV["PT_test_plan_template"] = template 

			@testplans = Utilities::JMXHelper.generate_testplans(@test_plan_template, @start_num_threads, @increase_step, @target_num_threads, @warmup_period, @loops, @duration)
			
			puts "Totally #{@testplans.size} test plans generated based on the template #{@test_plan_template} to run."

			Utilities::JMeterHelper.copy_resource_to_servers(@test_plans_path)
			
			@testplans.each do |test_plan|
				Utilities::JMXHelper.run_testplan(test_plan)
				#TODO, add the report page for different loads

			end

			ENV.delete("PT_test_plan_template")
			
			@kibana_helper.stop

		end

		def generate_test_report
			dashboard_links = {}
			report_link = @kibana_helper.generate_test_report
			    
			puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
			puts "Test result for #{template} can be found at Kibana from:"
			puts "#{report_link}"
			puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
			
			#record the test result, it will be later written to the test report
			@report_helper.add_result_for_test_plan template, time_from, time_to, "Report", report_link
			dashboard_links["Report"] = @kibana_helper.get_dashboard_id

		    if @testplans.count > 1

		    	mutiple_threads_report_link = @kibana_helper.generate_test_report_4_different_threads
		    	puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
				puts "The performance analysis for different threads settings of #{template} can be found at Kibana from:"
				puts "#{mutiple_threads_report_link}"
				puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
		    	@report_helper.add_result_for_test_plan template, time_from, time_to, 'Different Threads Report', mutiple_threads_report_link
		    	
		    	dashboard_links['Report for Different Threads'] = @kibana_helper.get_dashboard_id_4_different_threads
		    end

		    #generate the dashboard for analysis for different builds of the same test plan
			@kibana_helper.set_is_for_single_run false
		    mutiple_builds_report_link = @kibana_helper.generate_test_report_4_different_builds 
		    puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
			puts "The performance analysis for different builds of #{template} can be found at Kibana from:"
			puts "#{mutiple_builds_report_link}"
			puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
		    @report_helper.add_result_for_test_plan template, time_from, time_to, 'Different Builds Report', mutiple_builds_report_link
		    
		    dashboard_links['Report for Different Builds'] = @kibana_helper.get_dashboard_id_4_different_builds

		    dashboard_links['System Status'] = 'Metricbeat-system-overview'
		    
		    @kibana_helper.update_links_of_markdownpage  dashboard_links
		    @kibana_helper.update_test_detailed_info @test_detailed_info
		end

		def teardown_after_execution
			puts "-------------------------------"
			@end_time = DateTime.now
			puts "End To: #{@end_time}"
			puts "-------------------------------"
			ENV.delete("PT_test_plan_package")
			ENV.delete("PT_RunId")

			#generate the test report at last, and the html file will be copied to the folder of archived artifact of Jenkins
			@report_helper.generate_report "index.html"
			FileUtils.mv('index.html', @test_plans_path)
			FileUtils.cp('report.css', @test_plans_path)

			FileUtils.cp_r(@test_plans_path, @result_path)
			FileUtils.rm_rf(@test_plans_path)
			puts "All #{testplanTemplates.size } test plans have been finished."
		end

		def get_run_id
			@run_id
		end
	end
end

