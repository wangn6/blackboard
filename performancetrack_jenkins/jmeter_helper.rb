require_relative 'file_helper.rb'
module Utilities
	class JMeterHelper
		@@remote_servers = '10.208.5.214,10.208.5.169'
		@@jmeter_path = '/home/nwang/servers/apache-jmeter-3.0-server'
		def JMeterHelper.run_testplan(testplan, timeout = 0)
			jmeter_bin = `which jmeter`
			if(jmeter_bin == "")
				#default bin folder
				jmeter_bin = "#{@@jmeter_path}/bin/jmeter"
			else
				jmeter_bin = jmeter_bin.delete("\n")
			end

			if(@@remote_servers!='')
				system("#{jmeter_bin} -n -t #{testplan} -R #{@@remote_servers} -l #{testplan}.jtl")
			else
				system("#{jmeter_bin} -n -t #{testplan} -l #{testplan}.jtl")
			end
		end
		def JMeterHelper.start_remote_servers
			if(@@remote_servers!='')
				@@remote_servers.split(',').each do |remote_server|
					puts "Start the jmeter-server on the remote machine #{remote_server}"
					system("ssh #{remote_server} \"ps aux|grep jmeter|awk '{print \\$2}'|xargs kill -9\"")
					system("ssh #{remote_server} 'cd /home/nwang/servers/apache-jmeter-3.0-server/test_data; nohup ./../bin/jmeter-server > /dev/null 2>&1 &'")
				end
			end
		end
		def JMeterHelper.copy_resource_to_servers(test_plans_path)
			@@remote_servers.split(',').each do |remote_server|
				puts "Start to copy resources under folder of #{test_plans_path} to remote server #{remote_server} on #{@@jmeter_path}/test_data"
				FileHelper.scp_folder_to_remote(test_plans_path, remote_server, "#{@@jmeter_path}/test_data")
			end
		end
		def JMeterHelper.clear_test_data_folder
			@@remote_servers.split(',').each do |remote_server|
				puts "Start to clear resources on remote server #{remote_server}:#{@@jmeter_path}/test_data"
				FileHelper.clear_remote_folder(remote_server, "#{@@jmeter_path}/test_data")
			end
		end
	end
end
