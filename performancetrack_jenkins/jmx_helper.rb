require 'rubygems'
require 'json'
require 'nokogiri'
require 'fileutils'
require_relative 'jmeter_helper.rb'

module Utilities
	class JMXHelper

		# The contructor method, need a parameter of the teamplate path
		def initialize(testplanTemplate)
			@current_path = File.absolute_path(__FILE__)
			if(File.exist?(testplanTemplate))
				@testplanTemplate = testplanTemplate
				doc_content = File.new(testplanTemplate).read()
				@doc = Nokogiri.XML(doc_content)
				@testplan_absolutepath = File.absolute_path(testplanTemplate)
				@root_target_path = File.dirname(@testplan_absolutepath)
			else
				raise "The test plan #{testplanTemplate} does not exist"
			end
		end

	    # Modify the load settings of the test plan
		def modify_load_parameters(ramp_time, num_threads, duration, loops)
			if(ramp_time != nil)
				modify_warmup_period(ramp_time)
			end
			if(num_threads != nil)
				modify_thread_num(num_threads)
			end
			if(duration != nil)
				modify_duration(duration)
			end
			if(loops != nil)
				modify_loops(loops)
			end
		end

		#ingest the backend listener into the test plan's thread group
		def ingest_backend_listener()
			backend_listener = File.dirname(@current_path) + "/backendlistener.xml"
			backend_listener_segment = File.new(backend_listener).read()
			@doc.xpath("//jmeterTestPlan/hashTree/hashTree/hashTree").each do |thread_group|
				#thread_group.add_next_sibling(backend_listener_segment)
				thread_group.add_child(backend_listener_segment)
			end
		end

		# Save the modified test plan to a new one
		def generate_new_testplan(testplanName=nil)
			if(testplanName != nil && testplanName != "")
				File.new(testplanName, "w").write(@doc.to_xml)
				puts "New test plan #{ testplanName } is created successfully"
				return File.absolute_path(testplanName)
			else
				newTestPlanName = File.join(@root_target_path, "#{ File.basename(@testplan_absolutepath, '.jmx') }_threads_#{get_num_threads()}_loops_#{get_loops()}_duration_#{get_duration}_ramp_#{get_ramp_time()}.jmx" )
				File.new(newTestPlanName, "w").write(@doc.to_xml)
				puts "New test plan #{ newTestPlanName } is created successfully"
				return File.absolute_path(newTestPlanName)
			end
		end

		# The class method to generate more test plans based on the template, mainly focus on the load thread adjustment
		def JMXHelper.generate_testplans(testplan_template, start_num_threads, increase_step, target_num_threads, warmup_period, loops, duration = nil)
			test_plans = []
			if(start_num_threads == nil)
				helper = JMXHelper.new(testplan_template)
                helper.ingest_backend_listener
				#Reduce the threads to half because there're two JMeter Servers
				num_threads = helper.get_num_threads().to_i
				helper.modify_load_parameters(nil, num_threads/2, nil, nil)
                new_test_plan = helper.generate_new_testplan
                test_plans << File.absolute_path(new_test_plan)
			else
				num_threads = start_num_threads
				while(num_threads <= target_num_threads)
					helper = JMXHelper.new(testplan_template)
					helper.modify_load_parameters(warmup_period, num_threads/2, duration, loops)
					helper.ingest_backend_listener
					new_test_plan = helper.generate_new_testplan
					test_plans << File.absolute_path(new_test_plan)
					num_threads += increase_step
				end
			end
			return test_plans 
		end

		def JMXHelper.generate_testplan(testplan_template, threads, warmup_period, loops, duration)
			helper = JMXHelper.new(testplan_template)
            helper.ingest_backend_listener
			#Reduce the threads to half because there're two JMeter Servers
			helper.modify_load_parameters(warmup_period, threads/2, duration, loops)
            new_test_plan = helper.generate_new_testplan
            File.absolute_path(new_test_plan)
        end

		# get the test plan level parameters and this will be used to save to elasticsearch for futher analysis
		def get_testplan_parameters()
			variables = {}
			user_defined_variables = @doc.xpath('//jmeterTestPlan/hashTree/TestPlan/elementProp[@name="TestPlan.user_defined_variables"]/collectionProp/elementProp')
			user_defined_variables.each {|variable|
				name = variable.xpath('stringProp[@name="Argument.name"]').inner_html
				value = variable.xpath('stringProp[@name="Argument.value"]').inner_html
				variables[name] = value
			}
			return variables
		end

		# Call the JMeter to run the test plan/plans
		def JMXHelper.run_testplan(testplan)
			helper = JMXHelper.new(testplan)
			# Export the parameters related thus the JMeter can save them into the elasticsearch
			ENV["PT_num_threads"] = "#{helper.get_num_threads().to_i * 2}"
			ENV["PT_ramp_time"] = helper.get_ramp_time()
			ENV["PT_duration"] = helper.get_duration()
			ENV["PT_loops"] = helper.get_loops()
			ENV["PT_customized_parameters"] = helper.get_testplan_parameters().to_json
			ENV["PT_test_plan"] = File.basename(testplan)
			# Call JMeter to run the performance test
			Dir.chdir(File.dirname(testplan)) do
				puts "Start to run the test plan #{testplan}"
				puts "num_threads:#{ENV["PT_num_threads"]} ramp_time:#{ENV["PT_ramp_time"]} duration:#{ENV["PT_duration"]} loops:#{ENV["PT_loops"]} testplan:#{ENV["PT_test_plan"]}"
				JMeterHelper.run_testplan(testplan)
				puts "The execution for test plan #{ENV["PT_test_plan"]} is finished."
			end
			# Remove the environment variables after execution
			ENV.delete("PT_num_threads")
			ENV.delete("PT_ramp_time")
			ENV.delete("PT_duration")
			ENV.delete("PT_loops")
			ENV.delete("PT_customized_parameters")
			ENV.delete("PT_test_plan")
		end

		# private methods

		def modify_thread_num(num)
			@doc.xpath('//jmeterTestPlan/hashTree/hashTree/ThreadGroup/stringProp[@name="ThreadGroup.num_threads"]').first().inner_html = "#{num}"
		end

		def modify_warmup_period(warm_up_period)
			@doc.xpath('//jmeterTestPlan/hashTree/hashTree/ThreadGroup/stringProp[@name="ThreadGroup.ramp_time"]').first().inner_html = "#{warm_up_period}"
		end

		def modify_duration(duration)
			# when enable the duration, we'll set the Loop Count to forever
			#delete this property of loops at first if there's any
			loop_controller = @doc.xpath('//jmeterTestPlan/hashTree/hashTree/ThreadGroup/elementProp[@name="ThreadGroup.main_controller"]').first()
			if(loop_controller.at_xpath('intProp') != nil)
				loop_controller.at_xpath('intProp').content = -1
			else
				if(loop_controller.search('stringProp').count != 0)
					loop_controller.search('stringProp').remove
				end
				node = Nokogiri::XML::Node.new "intProp", @doc
				node['name'] = 'LoopController.loops'
				node.content = -1
				node.parent = loop_controller
			end
			@doc.xpath('//jmeterTestPlan/hashTree/hashTree/ThreadGroup/boolProp[@name="ThreadGroup.scheduler"]').first().inner_html = "true"
			@doc.xpath('//jmeterTestPlan/hashTree/hashTree/ThreadGroup/stringProp[@name="ThreadGroup.duration"]').first().inner_html = "#{duration}"
		end

		def modify_loops(loops)
			loop_controller = @doc.xpath('//jmeterTestPlan/hashTree/hashTree/ThreadGroup/elementProp[@name="ThreadGroup.main_controller"]').first()
			if(loop_controller.at_xpath('stringProp') != nil)
				loop_controller.at_xpath('stringProp').inner_html = "#{loops}"
			else
				if(loop_controller.search('intProp').count != 0)
					loop_controller.search('intProp').remove
				end
				node = Nokogiri::XML::Node.new "stringProp", @doc
				node['name'] = 'LoopController.loops'
				node.content = "#{loops}"
				node.parent = loop_controller
			end
		end

		def get_num_threads()
			@doc.xpath('//jmeterTestPlan/hashTree/hashTree/ThreadGroup/stringProp[@name="ThreadGroup.num_threads"]').first().inner_html
		end

		def get_ramp_time()
			@doc.xpath('//jmeterTestPlan/hashTree/hashTree/ThreadGroup/stringProp[@name="ThreadGroup.ramp_time"]').first().inner_html
		end

		def get_duration()
			@doc.xpath('//jmeterTestPlan/hashTree/hashTree/ThreadGroup/stringProp[@name="ThreadGroup.duration"]').first().inner_html
		end

		def get_loops()
			loop_config = @doc.xpath('//jmeterTestPlan/hashTree/hashTree/ThreadGroup/elementProp[@name="ThreadGroup.main_controller"]/stringProp[@name="LoopController.loops"]')
			if(loop_config.count == 0 )
				"Forever"
			else
				loop_config.first().inner_html 
			end
		end


	end
end
#helper = Utilities::JMXHelper.new '/Users/nwang/test.jmx'
#helper.modify_duration(30)
#helper.modify_loops(1000)
#helper.generate_new_testplan("/Users/nwang/new.jmx")