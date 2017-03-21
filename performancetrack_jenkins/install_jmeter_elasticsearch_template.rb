es_host = '10.208.5.140:9200'
`curl -XPOST #{es_host}/_template/jmeter_template -d '
{
    "order": 0,
    "template": "jmeter*",
    "settings": {},
    "mappings": {
      "SampleResult": {
        "properties": {
          "ContentType": {
            "type": "string"
          },
          "EndTime": {
            "format": "dateOptionalTime",
            "type": "date"
          },
          "IdleTime": {
            "type": "long"
          },
          "ElapsedTime": {
            "type": "long"
          },
          "ErrorCount": {
            "type": "long"
          },
          "Success": {
            "index": "not_analyzed",
            "type": "string"
          },
          "URL": {
            "index": "not_analyzed",
            "type": "string"
          },
	 "Host": {
	            "index": "not_analyzed",
	            "type": "string"
	},
	 "Path": {
	            "index": "not_analyzed",
	            "type": "string"
	},
          "MBaasBuild": {
            "index": "not_analyzed",
            "type": "string"
          },
          "Bytes": {
            "type": "long"
          },
          "AllThreads": {
            "type": "long"
          },
          "NormalizedTimestamp": {
            "format": "dateOptionalTime",
            "type": "date"
          },
          "DataType": {
            "index": "not_analyzed",
            "type": "string"
          },
          "ResponseTime": {
            "type": "long"
          },
          "SampleCount": {
            "type": "long"
          },
          "ConnectTime": {
            "type": "long"
          },
          "sku": {
            "index": "not_analyzed",
            "type": "string"
          },
          "RunId": {
            "index": "not_analyzed",
            "type": "string"
          },
          "timestamp": {
            "format": "dateOptionalTime",
            "type": "date"
          },
          "ResponseCode": {
            "index": "not_analyzed",
            "type": "string"
          },
          "StartTime": {
            "format": "dateOptionalTime",
            "type": "date"
          },
          "ResponseMessage": {
            "index": "not_analyzed",
            "type": "string"
          },
          "Assertions": {
            "properties": {
              "FailureMessage": {
                "index": "not_analyzed",
                "type": "string"
              },
              "Failure": {
                "type": "boolean"
              },
              "Name": {
                "index": "not_analyzed",
                "type": "string"
              }
            }
          },
          "Latency": {
            "type": "long"
          },
          "GrpThreads": {
            "type": "long"
          },
          "BodySize": {
            "type": "long"
          },
          "ThreadName": {
            "index": "not_analyzed",
            "type": "string"
          },
          "SampleLabel": {
            "index": "not_analyzed",
            "type": "string"
          },
	"MachineName": {
            "index": "not_analyzed",
            "type": "string"
          },
	"MachineIP": {
            "index": "not_analyzed",
            "type": "string"
          },
	"TestPlanName": {
            "index": "not_analyzed",
            "type": "string"
          }

        }
      }
    },
    "aliases": {}
  }

'`