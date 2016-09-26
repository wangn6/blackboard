require 'minitest'
require 'rest-client'
require 'minitest/autorun'
require_relative './rest-client-customized.rb'

class ExampleTest < Minitest::Unit::TestCase
    def test_example_01
        ENV['CLASSNAME'] = self.class.to_s
        ENV['TESTNAME'] = self.name
        RestClient.get 'http://localhost:9200/performance/execution/_search?size=100'
    end

    def test_example_02
        ENV['CLASSNAME'] = self.class.to_s
        ENV['TESTNAME'] = self.name

        body = {
            "aggs" => {
                "load_time_outlier" => {
                    "percentiles" => {
                        "field" => "start_time" 
                    }
                }
            }
        }
        RestClient.post 'http://localhost:9200/performance/execution/_search', body.to_json, {content_type: :json, accept: :json}
    end
end
