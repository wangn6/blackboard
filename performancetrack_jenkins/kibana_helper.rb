require 'rest-client'
require 'date'
require 'json'
require_relative 'elasticsearch_helper.rb'

module Utilities
	class KibanaHelper
		@@server = "http://10.208.7.183:5601"
		#@@server = "http://performance-tracker-qa.mobile.medu.com:5601"
		@@external_url = "http://performance-tracker-qa.mobile.medu.com:5601"
		@@kibana_server = RestClient::Resource.new(@@server)
		@@templates_path = File.join(File.dirname(File.absolute_path __FILE__), 'kibana_templates')
		@@kibana_version  = '5.1.2'
		@@empty_body = '{}'

		#The hosts information that will be used to filter the logs or the metrics from the server
		def KibanaHelper.Hosts_4_Projects
			{
				'planner-qa' => {
					'planner-backend' => 'planner-dev-vir-app-i-bb10f029'
				}
			}
		end

		def KibanaHelper.Dashboards
			{
				'Dashboard' => 'Planner_PerformanceTest_Dashboard',
				'Dashboard_Different_Threads' => 'Planner_PerformanceTest_Dashboard_Different_Threads',
				'Dashboard_Different_Builds' => 'Planner_PerformanceTest_Dashboard_Different_Builds',
				'Dashboard_Realtime_Monitoring' => 'Planner_PerformanceTest_Realtime_Monitoring',
				'Dashboard_Stress_Test' => 'Planner_StressTest_Dashboard'
			}
		end

		#FOR Spoak/Load Test, the threads are fixed
		#------------------------------------------
		def KibanaHelper.Charts_4_Fixed_Threads
			{
			#for a fix build and all samples
			'PassRate_Metric' => {'template' => 'PassRate_Metric' , 'source' => 'jmeter'},
			'PassRate_TimelionChart' => {'template' => 'PassRate_TimelionChart' , 'source' => 'jmeter'},
			#'ResponseCode_PieChart' => {'template' => 'ResponseCode_PieChart' , 'source' => 'jmeter'},

			#for a fix build and all successful samples
			'ResponseTime_Table' => {'template' => 'ResponseTime_Table' , 'source' => 'jmeter'},# the response time table for all successful samples
			'ThroughPut_Table' =>  {'template' => 'ThroughPut_Table' , 'source' => 'jmeter'},
			'ResponseTime_TimelionChart' => {'template' => 'ResponseTime_TimelionChart' , 'source' => 'jmeter'},

			#the logs monitor chart
			'LogsErrors_TimelionChart' =>  {'template' => 'LogsErrors_TimelionChart' , 'source' => 'filebeat'},

			#the server monitoring
			'Realtime_ServerMemory_LineChart' =>  {'template' => 'Realtime_ServerMemory_LineChart' , 'source' => 'metricbeat'},
			'Realtime_ServerCPU_LineChart' =>  {'template' => 'Realtime_ServerCPU_LineChart' , 'source' => 'metricbeat'},

			#the navigator
			'Navigator_MarkdownPage' => {'template' => 'Navigator_MarkdownPage' , 'source' => 'none'},
			'Stress_Test_Result' => {'template' => 'Stress_Test_Result', 'source' => 'none'},
			'Details_Info_About_Test' => {'template' => 'Details_Info_About_Test', 'source' => 'none'}

			}
		end

		def KibanaHelper.Charts_4_Result_Panels
			{
				
				'Load_Test_Result' => {'template' => 'Load_Test_Result', 'source' => 'none'},
				'Performance_Test_Result' => {'template' => 'Performance_Test_Result', 'source' => 'none'},
				'Spike_Test_Result' => {'template' => 'Spike_Test_Result', 'source' => 'none'}
			}
		end

		def KibanaHelper.Charts_4_Different_Threads
			{
			#for multiple builds
			'ResponseTime_LineChart_DifferentThreads' => {
				'template' =>  'ResponseTime_LineChart_DifferentThreads' , 
				'conditions' => {
					'ResponseCode' => 200, 
					'ErrorCount' => 0 
					} , 
				'source' => 'jmeter'
				},
			'Throughput_LineChart_DifferentThreads' => {
				'template' =>  'Throughput_LineChart_DifferentThreads' , 
				'conditions' => {}, 
				'source' => 'jmeter'
				}
			}
		end

		def KibanaHelper.Charts_4_Different_Builds
			{
			#for multiple builds
			'ResponseTime_LineChart_DifferentBuilds' => {
				'template' =>  'ResponseTime_LineChart_DifferentBuilds' ,
				'source' => 'jmeter',
				'conditions' => {
					'ResponseCode'=> 200,
					'ErrorCount'=>0
					}
				},
			#'ErrorRate_LineChart_DifferentBuilds' => {'template' =>  'ErrorRate_LineChart_DifferentBuilds' , 'source' => 'jmeter'}， 
			'Throughput_LineChart_DifferentBuilds' => {
				'template' =>  'Throughput_LineChart_DifferentBuilds' , 
				'source' => 'jmeter',
				'conditions' => {
					'ResponseCode'=> 200,
					'ErrorCount'=>0
					}
				}
			}
		end

		#the realtime charts to monitor the execution
		def KibanaHelper.RealtimeCharts_4_SingleRun
            {
            #for realtime monitor
            'Realtime_ResponseTime_LineChart' => {'template' =>  'Realtime_ResponseTime_LineChart' , 'source' => 'jmeter', 'conditions' => {'ResponseCode'=> 200,  'ErrorCount'=>0}},
			'Realtime_Throughput_LineChart' => {'template' =>  'Realtime_Throughput_LineChart' , 'source' => 'jmeter', 'conditions' => {'ResponseCode'=> 200,  'ErrorCount'=>0}},
            'Realtime_SampleCount_LineChart' => {'template' =>  'Realtime_SampleCount_LineChart' , 'source' => 'jmeter'},
			'Realtime_LogsCount_LineChart' =>  {'template' => 'Realtime_LogsCount_LineChart' , 'source' => 'filebeat'},
			'Realtime_ServerMemory_LineChart' =>  {'template' => 'Realtime_ServerMemory_LineChart' , 'source' => 'metricbeat'},
			'Realtime_ServerCPU_LineChart' =>  {'template' => 'Realtime_ServerCPU_LineChart' , 'source' => 'metricbeat'},
            'Realtime_ActiveThreads_LineChart' =>  {'template' => 'Realtime_ActiveThreads_LineChart' , 'source' => 'jmeter'}
             }
        end

		def KibanaHelper.refresh
			@@kibana_server['elasticsearch/.kibana/_refresh'].post @@empty_body, :content_type => 'application/json', :'kbn-version' => @@kibana_version
		end
		
		def KibanaHelper.build_query_string conditions
			query_string = ''
			if conditions.length > 0
				conditions.keys.each do |key|
				value = conditions[key]
					if query_string == ''
						query_string = "#{key}:#{value}"
					else
						query_string = "#{query_string} AND #{key}:#{value}"
					end
				end
			else
				query_string = '*'
			end
			query_string
		end

		def KibanaHelper.create_discover(dis_id, dis_title, conditions)
			json_file = 'sample_result_discover.json'
			file = File.new File.join @@templates_path, json_file
			json = JSON.parse file.read
			template = json['_source']
			test_type_constrain = { "EnvironmentVariables.test_type" => @test_type }
			query_string = KibanaHelper.build_query_string test_type_constrain.merge(conditions)
			template['kibanaSavedObjectMeta']['searchSourceJSON'] = template['kibanaSavedObjectMeta']['searchSourceJSON'].gsub 'QUERYSTRING', "#{query_string}"
			template['title'] = dis_title
			@@kibana_server["elasticsearch/.kibana/search/#{dis_id}/_create"].post template.to_json, :content_type => 'application/json', :'kbn-version' => @@kibana_version do |response, request, result, &block|
				#puts response
			end
			KibanaHelper.refresh
		end

		def KibanaHelper.create_visualization(json_file, vis_id, vis_title, discover_id, query_string = nil)
			file = File.new File.join @@templates_path, json_file
			json = JSON.parse file.read
			type = json['_type']
			template = json['_source']
			template['title'] = vis_title
			template['visState'] = template['visState'].gsub 'VISTITLE', vis_title

			if(template['savedSearchId'] != nil)
				template['savedSearchId'] = discover_id
			end
			
			#handle the visualization that the query is offered by the Kibana query
			if(query_string != nil)
				template['kibanaSavedObjectMeta']['searchSourceJSON'] = template['kibanaSavedObjectMeta']['searchSourceJSON'].gsub 'QUERYSTRING', query_string
			end
			@@kibana_server["elasticsearch/.kibana/visualization/#{vis_id}/_create"].post template.to_json, :content_type => 'application/json', :'kbn-version' => @@kibana_version do |response, request, result, &block|
				#puts response
			end
			KibanaHelper.refresh
		end

		def KibanaHelper.create_markdownpage(json_file, vis_id, vis_title, run_id)
			file = File.new File.join @@templates_path, json_file
			json = JSON.parse file.read
			template = json['_source']
			template['title'] = vis_title
			template['visState'] = template['visState'].gsub 'VISTITLE', vis_title
			@@kibana_server["elasticsearch/.kibana/visualization/#{vis_id}/_create"].post template.to_json, :content_type => 'application/json', :'kbn-version' => @@kibana_version do |response, request, result, &block|
				#puts response
			end
			KibanaHelper.refresh
		end

		def KibanaHelper.update_markdownpage_links(vis_id, update_links)
			template = ''
			@@kibana_server["elasticsearch/.kibana/visualization/#{vis_id}"].get :'kbn-version' => @@kibana_version do |response, request, result, &block|
				#puts response
				json = JSON.parse response.body
				template = json['_source']
			end
			visState = template['visState']
			visState_json = JSON.parse visState
			update_links.keys.each do |key|
				link = update_links[key]	
				segment_template = "- [#{key}](#/dashboard/#{link})\n\n"
				visState_json['params']['markdown'] += segment_template
			end
			template['visState'] = visState_json.to_json
			@@kibana_server["elasticsearch/.kibana/visualization/#{vis_id}"].post template.to_json, :content_type => 'application/json', :'kbn-version' => @@kibana_version do |response, request, result, &block|
				#puts response
			end
			KibanaHelper.refresh
		end

		def KibanaHelper.add_infomation_table(vis_id, test_plan_info)
			template = ''
			@@kibana_server["elasticsearch/.kibana/visualization/#{vis_id}"].get :'kbn-version' => @@kibana_version do |response, request, result, &block|
				#puts response
				json = JSON.parse response.body
				template = json['_source']
			end
			visState = template['visState']
			visState_json = JSON.parse visState
			visState_json['params']['markdown'] += "### #{test_plan_info['title']}\n\n"
			if(test_plan_info['value']!=nil)
				visState_json['params']['markdown'] += "# #{test_plan_info['value']}\n\n"
			end
			visState_json['params']['markdown'] += "| #{test_plan_info['parameters'].first.keys.join(' | ')} |\n"
			visState_json['params']['markdown'] += "|#{ " --- |"*(test_plan_info['parameters'].first.keys.size) }\n"
			test_plan_info['parameters'].each do |parameter|
				segment_template = "| #{parameter.values.join(' | ')} |\n"
				visState_json['params']['markdown'] += segment_template
			end
			template['visState'] = visState_json.to_json
			@@kibana_server["elasticsearch/.kibana/visualization/#{vis_id}"].post template.to_json, :content_type => 'application/json', :'kbn-version' => @@kibana_version do |response, request, result, &block|
				#puts response
			end
			KibanaHelper.refresh
		end

		def KibanaHelper.create_timelion(json_file, timelion_id, title, conditions={}, metrics='')
			query_string = KibanaHelper.build_query_string conditions
			file = File.new File.join @@templates_path, json_file
			json = JSON.parse file.read
			template = json['_source']
			template['title'] = title
			template['visState'] = template['visState'].gsub 'TIMELIONTITLE', title
			template['visState'] = template['visState'].gsub 'QUERYSTRING', query_string
			template['visState'] = template['visState'].gsub 'METRICSTRING', metrics
			@@kibana_server["elasticsearch/.kibana/visualization/#{timelion_id}/_create"].post template.to_json, :content_type => 'application/json', :'kbn-version' => @@kibana_version do |response, request, result, &block|
				#puts response
			end
			KibanaHelper.refresh
		end

		def KibanaHelper.create_passrate_timelion(json_file, timelion_id, title, run_id)

			file = File.new File.join @@templates_path, json_file
			json = JSON.parse file.read
			template = json['_source']
			template['title'] = title

			visState = JSON.parse template['visState']
			visState['title'] = title
			expressions = []
			expression_template = visState['params']["expression"].clone

			sample_labels = ElasticSearchHelper.search_unique_sample_labels run_id
			sample_labels.each{ |label|
				conditions = {}
				#conditions['RunId'] = run_id
				conditions['SampleLabel'] = "\"#{label}\""
				query_string = KibanaHelper.build_query_string conditions
				expression = expression_template.gsub 'QUERYSTRING', query_string
				expressions << expression
			}
			expressions << ".static(value=99, label='Acceptable Passrate')"
			
			visState['params']["expression"] = expressions.join ','

			template['visState'] = visState.to_json
			
			@@kibana_server["elasticsearch/.kibana/visualization/#{timelion_id}/_create"].post template.to_json, :content_type => 'application/json', :'kbn-version' => @@kibana_version do |response, request, result, &block|
				#puts response
			end
			KibanaHelper.refresh
		end

#instance functions		

		def initialize(test_plan_template, run_id, project, is_for_single_run = true, test_type = 'load_test')
			@time_start = nil
			@time_to = nil
			@test_plan_template = test_plan_template
			@run_id = run_id
			@project = project
			@is_for_single_run = is_for_single_run
			@test_type = test_type
		end

		def start()
			@time_start = DateTime.now
			puts "Start From: #{@time_start}"
			@origin_time_start = @time_start.clone
			@time_start = @time_start - Rational(10, 86400)
		end

		def stop()
			@time_to = DateTime.now
			@origin_time_to = @time_to.clone
			puts "Stop at: #{@time_to}"
			#Add 10 seconds to handle the possible latency of the logs handling
			@time_to = @time_to + Rational(10, 86400)
		end

		def set_is_for_single_run is_for_single_run
			@is_for_single_run = is_for_single_run
		end

		def update_links_of_markdownpage links_to_update = {}
			KibanaHelper.Charts_4_Fixed_Threads.keys.each do |key|
				if key.downcase.include? 'navigator_markdown'
					vis_id = "#{key.downcase}_#{@run_id}"
					internal_links_to_update = {
						'Report' => get_dashboard_id,
						'Report for Different Builds' => get_dashboard_id_4_different_builds
					}
					KibanaHelper.update_markdownpage_links(vis_id, links_to_update.merge(internal_links_to_update))
				end
			end
		end

		def update_test_detailed_info test_detailed_info
			KibanaHelper.Charts_4_Fixed_Threads.keys.each do |key|
				if key.downcase.include? 'details_info_about_test'
					vis_id = "#{key.downcase}_#{@run_id}"
					internal_info = {
						"Start Time" => @time_start,
						"End Time" => @time_to,
						"Project" => @project
					}
					
					info = test_detailed_info['parameters'].merge internal_info
					test_detailed_info['title'] = @test_plan_template
					test_detailed_info['parameters'] = []
					info.keys.each do |key|
						test_detailed_info['parameters'] << {'Key' => key, 'Value' => info[key]}
					end
					KibanaHelper.add_infomation_table(vis_id, test_detailed_info)
				end
			end
		end

		def update_stress_result_panel stress_test_result
			vis_id = "#{'Stress_Test_Result'.downcase}_#{@run_id}"
			KibanaHelper.add_infomation_table(vis_id, stress_test_result)
		end

		def get_realtime_dashboard_id
			dashboard_id = "realtime_#{@run_id}"
		end

		def get_dashboard_id
			@run_id
		end

		def get_dashboard_id_4_different_threads
			dashboard_id = "multiple-threads-#{@run_id}"
		end

		def get_dashboard_id_4_different_builds
			dashboard_id = "multiple-builds-#{@run_id}"
		end

		#Generate the dashboart to monitor the realtime execution
		def generate_realtime_dashboard
			dashboard_id = get_realtime_dashboard_id
			create_dashboard  dashboard_id, KibanaHelper.RealtimeCharts_4_SingleRun, 'Dashboard_Realtime_Monitoring'
			get_dashboard_url dashboard_id
		end

		#Generate the final test report for this execution
		def generate_test_report
			dashboard_id = get_dashboard_id
			create_dashboard  dashboard_id, KibanaHelper.Charts_4_Fixed_Threads, 'Dashboard'
			get_dashboard_url dashboard_id
		end

		def generate_stress_test_report
			dashboard_id = get_dashboard_id
			create_dashboard  dashboard_id, KibanaHelper.Charts_4_Fixed_Threads, 'Dashboard_Stress_Test'
			get_dashboard_url dashboard_id
		end

		def generate_test_report_4_different_threads
			dashboard_id = get_dashboard_id_4_different_threads
			create_dashboard dashboard_id, KibanaHelper.Charts_4_Different_Threads, 'Dashboard_Different_Threads'
			get_dashboard_url dashboard_id
		end

		def generate_test_report_4_different_builds 
			dashboard_id = get_dashboard_id_4_different_builds
			@time_start = @time_start << 1
			create_dashboard dashboard_id, KibanaHelper.Charts_4_Different_Builds, 'Dashboard_Different_Builds'
			@time_start = @time_start >> 1
			get_dashboard_url dashboard_id
		end

		def create_visualizations charts
			results = {}
			discover_id = ''
			charts.keys.each do |key|
                template = "#{charts[key]['template'].downcase}.json"
                vis_id = "#{key.downcase}_#{@run_id}"
                conditions = charts[key]['conditions']
                if conditions == nil
                	conditions = {}
                end
                if(charts[key]['source'] == 'jmeter')
                	#add the run_id and test plan template name into the conditions
                	if @is_for_single_run
                		conditions['RunId'] = @run_id
                	end
                	conditions['EnvironmentVariables.test_plan_template'] = @test_plan_template
                elsif (charts[key]['source'] == 'filebeat')
                	#add the host name into the conditions
                	conditions['beat.hostname'] = KibanaHelper.Hosts_4_Projects["#{@project}"].values.first#TODO
                elsif(charts[key]['source'] == 'metricbeat')
                	#add the host name into the conditions
					conditions['beat.hostname'] = KibanaHelper.Hosts_4_Projects["#{@project}"].values.first#TODO
                else
                	#do nothing
                end
                if conditions != nil
                	discover_id = "#{@run_id}-#{Time.now.to_i}"
                	sleep 1
                	KibanaHelper.create_discover(discover_id, discover_id, conditions)
                end
                if key.downcase.include? 'passrate_timelionchart'#this chart is quite special, so here we need to handle it seperately
                	KibanaHelper.create_passrate_timelion(template, vis_id, key, @run_id)
                elsif key.downcase.include? 'timelion'
                    KibanaHelper.create_timelion(template, vis_id, key, {})
                elsif key.downcase.include? 'markdown'
                   	KibanaHelper.create_markdownpage(template, vis_id, key, @run_id)
                else
                	KibanaHelper.create_visualization(template, vis_id, key, discover_id)
                end
                results[key] = vis_id
            end
            results
		end

		def create_dashboard(dashboard_id, charts, dashboard_type)
			visualizations = create_visualizations(charts)
			#the dashboard
			name = KibanaHelper.Dashboards[dashboard_type]
			json_file = "#{name.downcase}.json"
			file = File.new File.join @@templates_path, json_file
			json = JSON.parse file.read
			template = json['_source']
			#update the panel content IDs
			visualizations.keys.each do |key|
				template["panelsJSON"] = template["panelsJSON"].gsub key, visualizations[key]
			end
			template['title'] = dashboard_id
			template['timeRestore'] = true
			template['timeFrom'] = @time_start.to_time.utc.strftime("%Y-%m-%dT%H:%M:%S.000Z")
			if @time_to == nil
				template['timeTo'] = 'now'
			else
                template['timeTo'] = @time_to.to_time.utc.strftime("%Y-%m-%dT%H:%M:%S.000Z")
			end
			@@kibana_server["elasticsearch/.kibana/dashboard/#{dashboard_id}/_create"].post template.to_json, :content_type => 'application/json', :'kbn-version' => @@kibana_version do |response, request, result, &block|
				#puts response
			end
			KibanaHelper.refresh
		end

		def get_start_time
			@origin_time_start
		end

		def get_end_time
			@origin_time_to
		end

		def get_discover_url(discover_id)
			url = "#{@@external_url}/app/kibana#/discover/#{discover_id}?_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:'#{@time_start.strftime("%Y-%m-%dT%H:%M:%S.000Z")}',mode:quick,to:'#{@time_to.strftime("%Y-%m-%dT%H:%M:%S.000Z")}'))"
		end

		def get_visualization_url(vis_id)
			url = "#{@@external_url}/app/kibana#/visualization/#{vis_id}?_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:'#{@time_start.strftime("%Y-%m-%dT%H:%M:%S.000Z")}',mode:quick,to:'#{@time_to.strftime("%Y-%m-%dT%H:%M:%S.000Z")}'))"
		end

		def get_dashboard_url(dashboard_id)
			url = "#{@@external_url}/app/kibana#/dashboard/#{dashboard_id}"#?_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:'#{@time_start.strftime("%Y-%m-%dT%H:%M:%S.000Z")}',mode:absolute,timezone:Asia%2FShanghai,to:'#{@time_to.strftime("%Y-%m-%dT%H:%M:%S.000Z")}'))"
		end
	end
end

#json_file = 'PassRate_TimelionChart.json'
#timelion_id = 'neil_wang_1234'
#title = timelion_id
#run_id = '67558c96-2eee-4342-92de-378147666ecd'
#Utilities::KibanaHelper.create_passrate_timelion(json_file, timelion_id, title, run_id)
#Utilities::KibanaHelper.add_infomation_table('details_info_about_test_e75a3b4c-a217-4c41-bedf-45476ab36477', {'name'=> 'Great.jmx', 'parameters' => {"Hello World" => "Great"}})
