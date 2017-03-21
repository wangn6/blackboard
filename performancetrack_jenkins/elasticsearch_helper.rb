require 'elasticsearch'
require 'securerandom'

module Utilities
    class ElasticSearchHelper
        @@es_host = 'http://10.208.7.183:9200'
        #@@es_host = "http://performance-tracker-qa.mobile.medu.com:9200"
        @@index_name = 'jmeter-elasticsearch-*'

        @@es_client = nil

        def self.get_es_client
            if @@es_client.nil?
                @@es_client = Elasticsearch::Client.new host: @@es_host, log: false
            end
            @@es_client
        end

        def self.search_unique_sample_labels run_id
            client = get_es_client
            response = client.search index: @@index_name, body: {
                query: {
                    term: { RunId: "#{run_id}" }
                },
                size: 0,
                aggs: {
                    SampleResult: {
                        terms: { field: 'SampleLabel' }
                    }
                }
            }
            response["aggregations"]["SampleResult"]["buckets"].map{|item| item["key"]}
        end

        def self.get_average_response_time run_id, threads, sample_label
            client = get_es_client
            response = client.search index: @@index_name, body: {
                query: {
                    bool: {
                        must: [
                            {
                                term: {
                                    RunId: "#{run_id}"
                                }
                            }, 
                            {
                                term: {
                                    :"EnvironmentVariables.num_threads.keyword" => "#{threads}"
                                }
                            },
                            {
                                term: {
                                    SampleLabel: "#{sample_label}"
                                }
                            },
                            {
                                term: {
                                    ErrorCount: 0
                                }
                            }
                        ]
                    } 
                },
                aggs: {
                    SampleResult: {
                        avg: {
                            field: "ResponseTime"
                        }
                    }
                },
                size: 0
            }
            value = response['aggregations']['SampleResult']['value']
            value.to_f
        end

        def self.get_error_rate run_id, threads, sample_label
            client = get_es_client
            response = client.search index: @@index_name, body: {
                query: {
                    bool: {
                        must: [
                            {
                                term: {
                                    RunId: "#{run_id}"
                                }
                            }, 
                            {
                                term: {
                                    :"EnvironmentVariables.num_threads.keyword" => "#{threads}"
                                }
                            },
                            {
                                term: {
                                    SampleLabel: "#{sample_label}"
                                }
                            },
                            {
                                term: {
                                    ErrorCount: 0
                                }
                            }
                        ]
                    } 
                },
                size: 0
            }
            success =  response['hits']['total']
            response = client.search index: @@index_name, body: {
                query: {
                    bool: {
                        must: [
                            {
                                term: {
                                    RunId: "#{run_id}"
                                }
                            }, 
                            {
                                term: {
                                    :"EnvironmentVariables.num_threads.keyword" => "#{threads}"
                                }
                            },
                            {
                                term: {
                                    SampleLabel: "#{sample_label}"
                                }
                            }
                        ]
                    } 
                },
                size: 0
            }
            total = response['hits']['total']
            error_rate = 1.0
            if(total.to_i != 0)
                error_rate = ((total.to_f - success.to_f))/(total.to_f)
            end
            error_rate
        end
    end
end

#run_id = '8a704e13-0f3a-4ab5-8679-a77a649b37f3'
#samples = Utilities::ElasticSearchHelper.search_unique_sample_labels run_id
#samples.each do |sample|
#   puts sample
#    Utilities::ElasticSearchHelper.get_error_rate run_id, 10, sample
#end