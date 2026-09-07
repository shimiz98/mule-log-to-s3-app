package myapp;

import java.util.Collections;

import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.cloudwatchlogs.CloudWatchLogsClient;
import software.amazon.awssdk.services.cloudwatchlogs.model.InputLogEvent;
import software.amazon.awssdk.services.cloudwatchlogs.model.PutLogEventsRequest;
import software.amazon.awssdk.services.cloudwatchlogs.model.PutLogEventsResponse;

public class MyDebugFunctions {
	static public String putCloudWatchLogs(Object arg) {
		Region awsRegion = Region.of("");

		String logGroupName = "WeathertopJavaContainerLogs"; // args[0];
		String logStreamName = "weathertop-java-stream"; // args[1];

		CloudWatchLogsClient cloudWatchLogsClient = CloudWatchLogsClient.builder().region(awsRegion).build();

		String argStr;
		if (arg == null) {
			argStr = "";
		} else {
			argStr = ": " + arg.toString();
		}

		InputLogEvent logEvent = InputLogEvent.builder()
				.message("Hello world from " + MyDebugFunctions.class.getName() + argStr)
				.timestamp(System.currentTimeMillis())
				.build();
		PutLogEventsRequest req = PutLogEventsRequest.builder()
				.logGroupName(logGroupName)
				.logStreamName(logStreamName)
				.logEvents(Collections.singleton(logEvent))
				.build();

		PutLogEventsResponse res = cloudWatchLogsClient.putLogEvents(req);
		return res.toString();
	}
}
