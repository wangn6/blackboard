require 'minitest'
require 'rest-client'
require 'minitest/autorun'
require_relative './rest-client-customized.rb'

class TestBase < Minitest::Test
    def setup
        ENV['CLASSNAME'] = self.class.to_s
        ENV['TESTNAME'] = self.name
    end

    def teardown

    end
end
