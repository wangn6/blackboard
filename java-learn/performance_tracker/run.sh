#!/bin/bash


export PT_MBaasBuild='200'
export PT_B2Build='1.6.3'

export PT_RunId="$( python -c 'import uuid; print str(uuid.uuid1())' )"
export PT_TestPlan=/Users/nwang/works/2016/performance_tracker/pepstandalone_cluster.jmx

remote_servers=nwang.local:4000
jmeter_local_executor=/Users/nwang/servers/apache-jmeter-3.0-server/bin/jmeter

function ssh_execute_command
{
	remote_host=$1
	user_name=$2
	password=$3
	commandline=$4
	sshpass -p $password ssh $user_name@$remote_host $commandline &
}

function start_jmeter_controller_remotely
{
	controller_host=$1
	user_name=$2
	password=$3

	ssh_execute_command $controller_host $user_name $password "${jmeter_local_executor} -n -t ${test_plan} -R ${remote_servers}"
}

function start_jmeter_controller_locally
{
	newTestPlan=$( ruby ./ingest_backend_listener.rb "${PT_TestPlan}" )
	echo ${newTestPlan}
	"${jmeter_local_executor}" -n -t "${newTestPlan}" -R "${remote_servers}"
}

function start_remote_logstash
{
	echo "TODO"
}

function stoop_remote_logstash
{
	echo "TODO"
}

#To generate an GUID which will be used to identify the execution between the client and the server
function generate_uuid
{
	return "$( python -c 'import uuid; print str(uuid.uuid1())' )"
}


#jmeter_local_executor -n -t test_plan 

# -D[prop_name]=[value]
# defines a java system property value.
# -J[prop_name]=[value]
# defines a local JMeter property.
# -G[prop_name]=[value]
# defines a JMeter property to be sent to all remote servers.
# -G[propertyfile]
# defines a file containing JMeter properties to be sent to all remote servers.
# -L[category]=[priority]
# overrides a logging setting, setting a particular category to the given priority level.


#jmeter_local_executor -n -t test_plan -R$remote_servers -Gproperty

start_jmeter_controller_locally
