#!/bin/bash
# This is to run all the tests
curl -XDELETE http://localhost:9200/performance
i=120
while [ $i -gt 0 ]
do
    TASKNAME='DemoAutomationTest'
    build=$[120 - $i]
    BUILDNAME='DemoBuild 2.0.0.'$build
    ruby sample_tests.rb
    i=$[$i - 1]
    sleep 1

done