require 'tempfile'
require 'mime/types'
require 'cgi'
require 'netrc'
require 'set'
require 'json'
require_relative 'es_utils.rb'

module RestClient
    class Request
        alias :_execute :execute
        def execute & block
            
            start_time = Time.now

            _execute &block

            end_time = Time.now
            task_name = ENV['TASKNAME']
            build_name = ENV['BUILDNAME']
            class_name = ENV['CLASSNAME']
            test_name = ENV['TESTNAME']
            duration = end_time - start_time
            ESUtils.initialize_es_index
            ESUtils.insert_record task_name, build_name, class_name, test_name, duration, start_time, end_time, uri, method, processed_headers

        end
    end
end