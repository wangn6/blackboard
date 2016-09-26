require 'tempfile'
require 'mime/types'
require 'cgi'
require 'netrc'
require 'set'
require 'json'
require_relative 'es_utils.rb'

module RestClient
    class Request
        def execute & block
            # With 2.0.0+, net/http accepts URI objects in requests and handles wrapping
            # IPv6 addresses in [] for use in the Host request header.
            
            start_time = Time.now
            transmit uri, net_http_request_class(method).new(uri, processed_headers), payload, & block
            end_time = Time.now
            task_name = ENV['TASKNAME']
            build_name = ENV['BUILDNAME']
            class_name = ENV['CLASSNAME']
            test_name = ENV['TESTNAME']
            _payload = ENV['PAYLOAD'].nil? == true ? {} : JSON.parse(ENV['PAYLOAD'])
            duration = end_time - start_time

            ESUtils.initialize_es_index
            ESUtils.insert_record task_name, build_name, class_name, test_name, duration, start_time, end_time, uri, method, processed_headers, _payload
        ensure
            payload.close if payload
        end
    end

    module Payload
        extend self

        def generate(params)
          if params.is_a?(String)
            ENV['PAYLOAD'] = params
            Base.new(params)
          elsif params.is_a?(Hash)
            if params.delete(:multipart) == true || has_file?(params)
              Multipart.new(params)
            else
              UrlEncoded.new(params)
            end
          elsif params.respond_to?(:read)
            Streamed.new(params)
          else
            nil
          end
        end
    end
end