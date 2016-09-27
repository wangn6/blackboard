require 'elasticsearch'
require 'securerandom'

module ESUtils

    @@es_host = 'localhost'
    @@index_name = 'performance'
    @@index_settings = '{
        "settings" : {
            "number_of_shards" : 1
        },
        "mappings" : {
            "execution" : {
                "properties" : {
                    "task_name" : { "type" : "string", "index" : "not_analyzed" },
                    "build_name" : { "type" : "string", "index" : "not_analyzed" },
                    "class_name" : { "type" : "string", "index" : "not_analyzed" },
                    "test_name" : { "type" : "string", "index" : "not_analyzed" },
                    "start_time" : { "type" : "date", "index" : "not_analyzed" },          
                    "end_time" : { "type" : "date", "index" : "not_analyzed" },
                    "duration" : { "type" : "float", "index" : "not_analyzed" },
                    "create_time" : { "type" : "date", "index" : "not_analyzed" },
                    "update_time" : { "type" : "date", "index" : "not_analyzed" },
                    "uri" : { "type" : "string", "index" : "not_analyzed" },
                    "method" : { "type" : "string", "index" : "not_analyzed" },
                    "payload" : { "type" : "object" },
                    "headers" : { "type" : "object" },
                    "response_code" : { "type" : "string", "index" : "not_analyzed" },
                    "response" : { "type" : "object"},
                    "comments" : { "type" : "string", "index" : "not_analyzed" }
                }
            }
        }
    }'
    @@es_client = nil

    def self.get_es_client
        if @@es_client.nil?
            @@es_client = Elasticsearch::Client.new host: @@es_host, log: true
        end
        @@es_client
    end

    def self.initialize_es_index
        client = get_es_client
        exists = false
        begin
            response = client.perform_request "GET", @@index_name
            exists = true
        rescue
            exists = false
        end
        if (!exists)
            client.perform_request "PUT", @@index_name, {}, @@index_settings
        end
    end

    def self.insert_record task_name, build_name, class_name, test_name, duration, start_time, end_time, uri, method, headers={}, payload={}, response_code = '200', response={}, comments = ''
        client = get_es_client
        id = SecureRandom.uuid + '-' + Time.now.to_i.to_s
        body = {
            task_name: task_name,
            build_name: build_name,
            class_name: class_name,
            test_name: test_name,
            create_time: Time.now.utc.iso8601,
            duration: duration,
            start_time: start_time.utc.iso8601,
            end_time: end_time.utc.iso8601,
            uri: uri,
            method: method,
            headers: headers,
            payload: payload,
            response_code: response_code,
            response: response,
            comments: comments
        }
        # create new record in ES
        begin
            client.create index: @@index_name, id: id, type: "execution", body: body
        rescue => e
            puts e.message
            puts e.backtrace
        end

    end 
end
#ESUtils.initialize_es_index
