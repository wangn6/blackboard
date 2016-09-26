require 'minitest'
require 'rest-client'
require 'minitest/autorun'
require_relative './rest-client-customized.rb'

class ExampleTest < Minitest::Unit::TestCase
    def test_example_01
        ENV['CLASSNAME'] = self.class.to_s
        ENV['TESTNAME'] = self.name
        RestClient.get 'http://localhost:9200/_all'
    end
end
