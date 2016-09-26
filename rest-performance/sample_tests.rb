require_relative 'test_base.rb'

class SampleCases4Demo < TestBase
    def test_example_01
        RestClient.get 'http://localhost:9200/performance/execution/_search?size=100'
    end

    def test_example_02
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