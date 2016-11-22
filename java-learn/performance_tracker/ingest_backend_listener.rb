# Usage:
# add_backend_listener_segment.rb testplan.jmx

require 'nokogiri'

tool_path = File.absolute_path(__FILE__)

backend_listener = File.dirname(tool_path) + "/backendlistener.xml"

testplanName = ARGV[0] #"/Users/nwang/works/2016/performance_tracker/pepstandalone.jmx"

root_path = File.absolute_path(testplanName)

newTestPlanName =  File.join( File.dirname(root_path), File.basename(root_path, File.extname(root_path)) + "_ingested" + File.extname(root_path))

doc_content = File.new(testplanName).read()

backend_listener_segment = File.new(backend_listener).read()

doc = Nokogiri.XML(doc_content)

doc.xpath("//jmeterTestPlan/hashTree/hashTree/hashTree").first().add_next_sibling(backend_listener_segment)

File.new(newTestPlanName, "w").write(doc.to_xml)

puts newTestPlanName