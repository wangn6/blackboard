package com.blackboard;

import java.net.InetSocketAddress;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.jmeter.assertions.AssertionResult;
import org.apache.jmeter.config.Arguments;
import org.apache.jmeter.samplers.SampleResult;
import org.apache.jmeter.visualizers.backend.AbstractBackendListenerClient;
import org.apache.jmeter.visualizers.backend.BackendListenerContext;
import org.apache.jorphan.logging.LoggingManager;
import org.apache.log.Logger;

import org.elasticsearch.client.transport.TransportClient;
import org.elasticsearch.common.settings.Settings;
import org.elasticsearch.common.transport.InetSocketTransportAddress;


/**
 * Created by nwang on 01/11/2016.
 */
public class PerformanceTrackerClient extends
        AbstractBackendListenerClient {
    private static TransportClient client;
    private String indexName;
    private String dateTimeAppendFormat;
    private String sampleType;
    private String runId;
    private String mBaasBuild;
    private long offset;
    private static final int DEFAULT_ELASTICSEARCH_PORT = 9300;
    private static final String TIMESTAMP = "timestamp";
    private static final String VAR_DELIMITER = "~";
    private static final String VALUE_DELIMITER = "=";
    private static final Logger LOGGER = LoggingManager.getLoggerForClass();


    public static void main(String[] args) {

        try {
            Settings.Builder builder = Settings.settingsBuilder();
            builder = builder.put("cluster.name", "elasticsearch");
            Settings settings = builder.build();

            client = TransportClient.builder().settings(settings).build();
        }
        catch (Exception ex)
        {
            LOGGER.info("Exeption occured when initialize the test");
            LOGGER.info(ex.getMessage());
            LOGGER.info(ex.getStackTrace().toString());
            LOGGER.info(ex.getCause().toString());
            ex.printStackTrace();
        }
        client.addTransportAddress(new InetSocketTransportAddress(new InetSocketAddress("localhost", 9200)));

    }

    @Override
    public void handleSampleResults(List<SampleResult> results,
                                    BackendListenerContext context) {
        LOGGER.info("handleSampleResults : " + results.size());

        String indexNameToUse = indexName;
        for (SampleResult result : results) {
            Map<String, Object> jsonObject = getMap(result);
            if (dateTimeAppendFormat != null) {
                SimpleDateFormat sdf = new SimpleDateFormat(dateTimeAppendFormat);
                indexNameToUse = indexName + sdf.format(jsonObject.get(TIMESTAMP));
            }
            client.prepareIndex(indexNameToUse, sampleType).setSource(jsonObject).execute().actionGet();
        }

    }

    private Map<String, Object> getMap(SampleResult result) {
        Map<String, Object> map = new HashMap<String, Object>();
        String[] sampleLabels = result.getSampleLabel().split(VAR_DELIMITER);
        map.put("SampleLabel", sampleLabels[0]);
        for (int i = 1; i < sampleLabels.length; i++) {
            String[] varNameAndValue = sampleLabels[i].split(VALUE_DELIMITER);
            map.put(varNameAndValue[0], varNameAndValue[1]);
        }

        map.put("ResponseTime", result.getTime());
        map.put("ElapsedTime", result.getTime());
        map.put("ResponseCode", result.getResponseCode());
        map.put("ResponseMessage", result.getResponseMessage());
        map.put("ThreadName", result.getThreadName());
        map.put("DataType", result.getDataType());
        map.put("Success", String.valueOf(result.isSuccessful()));
        //map.put("FailureMessage", result.get);
        map.put("GrpThreads", result.getGroupThreads());
        map.put("AllThreads", result.getAllThreads());
        map.put("URL", result.getUrlAsString());
        map.put("Latency", result.getLatency());
        map.put("ConnectTime", result.getConnectTime());
        map.put("SampleCount", result.getSampleCount());
        map.put("ErrorCount", result.getErrorCount());
        map.put("Bytes", result.getBytes());
        map.put("BodySize", result.getBodySize());
        map.put("ContentType", result.getContentType());
        //map.put("HostName", result.get);
        map.put("IdleTime", result.getIdleTime());
        map.put(TIMESTAMP, new Date(result.getTimeStamp()));
        map.put("NormalizedTimestamp", new Date(result.getTimeStamp() - offset));
        map.put("StartTime", new Date(result.getStartTime()));
        map.put("EndTime", new Date(result.getEndTime()));
        map.put("RunId", runId);
        map.put("MBaasBuild", mBaasBuild);
        //TODO assertion results

        AssertionResult[] assertions = result.getAssertionResults();
        int count = 0;
        if (assertions != null) {
            Map<String, Object>[] assertionArray = new HashMap[assertions.length];
            for (AssertionResult assertionResult : assertions) {
                Map<String, Object> assertionMap = new HashMap<String, Object>();
                assertionMap.put("Failure", assertionResult.isError() || assertionResult.isFailure());
                assertionMap.put("FailureMessage", assertionResult.getFailureMessage());
                assertionMap.put("Name", assertionResult.getName());
                assertionArray[count++] = assertionMap;
            }
            map.put("Assertions", assertionArray);
        }
        return map;
    }

    @Override
    public void setupTest(BackendListenerContext context) throws Exception {

        LOGGER.info("SetupTest");

        String elasticsearchCluster = context.getParameter("elasticsearchCluster");

        String[] servers = elasticsearchCluster.split(",");

        indexName = context.getParameter("indexName");
        dateTimeAppendFormat = context.getParameter("dateTimeAppendFormat");
        if (dateTimeAppendFormat != null && dateTimeAppendFormat.trim().equals("")) {
            dateTimeAppendFormat = null;
        }
        sampleType = context.getParameter("sampleType");
        try {
            Settings.Builder builder = Settings.settingsBuilder();
            builder = builder.put("cluster.name", "elasticsearch");
            Settings settings = builder.build();

            client = TransportClient.builder().settings(settings).build();
        }
        catch (Exception ex)
        {
            LOGGER.info("Exeption occured when initialize the test");
            LOGGER.info(ex.getMessage());
            LOGGER.info(ex.getStackTrace().toString());
            LOGGER.info(ex.getCause().toString());
            ex.printStackTrace();
        }

        for (String serverPort : servers) {
            String[] serverAndPort = serverPort.split(":");
            int port = DEFAULT_ELASTICSEARCH_PORT;
            if (serverAndPort.length == 2) {
                port = Integer.parseInt(serverAndPort[1]);
            }
            client.addTransportAddress(new InetSocketTransportAddress(new InetSocketAddress(serverAndPort[0], port)));
        }
        String normalizedTime = context.getParameter("normalizedTime");
        if (normalizedTime != null && normalizedTime.trim().length() > 0) {
            SimpleDateFormat sdf2 = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSSX");
            Date d = sdf2.parse(normalizedTime);
            long normalizedDate = d.getTime();
            Date now = new Date();
            offset = now.getTime() - normalizedDate;
        }
        runId = context.getParameter("runId");
        mBaasBuild = context.getParameter("mbaasBuild");

        super.setupTest(context);
    }

    @Override
    public Arguments getDefaultParameters() {
        LOGGER.info("getDefaultParameters");
        Arguments arguments = new Arguments();
        arguments.addArgument("elasticsearchCluster", "localhost" + DEFAULT_ELASTICSEARCH_PORT);
        arguments.addArgument("indexName", "jmeter-elasticsearch");
        arguments.addArgument("sampleType", "SampleResult");
        arguments.addArgument("dateTimeAppendFormat", "-yyyy-MM-DD");
        arguments.addArgument("normalizedTime", "2015-01-01 00:00:00.000-00:00");
        arguments.addArgument("runId", "${__UUID()}");
        arguments.addArgument("mbaasBuild", "123");
        arguments.addArgument("b2Build","123");
        arguments.addArgument("otherParameter","other");

        //arguments.addArgument("summaryOnly", "true");
        //arguments.addArgument("samplersList", "");
        return arguments;


    }

    @Override
    public void teardownTest(BackendListenerContext context) throws Exception {
        LOGGER.info("teardownTest");
        client.close();
        super.teardownTest(context);
    }

}
