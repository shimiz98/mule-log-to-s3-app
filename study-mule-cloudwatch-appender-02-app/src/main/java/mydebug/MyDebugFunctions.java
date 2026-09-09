package mydebug;

import java.io.ByteArrayInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.lang.management.ManagementFactory;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Collections;
import java.util.List;

import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.cloudwatchlogs.CloudWatchLogsClient;
import software.amazon.awssdk.services.cloudwatchlogs.model.InputLogEvent;
import software.amazon.awssdk.services.cloudwatchlogs.model.PutLogEventsRequest;
import software.amazon.awssdk.services.cloudwatchlogs.model.PutLogEventsResponse;

public class MyDebugFunctions {
	public static List<String> getJvmCommandLineArgs() {
		return ManagementFactory.getRuntimeMXBean().getInputArguments();
	}

	public static String putCloudWatchLogs(String arg) {
		Region awsRegion = Region.of("ap-northeast-1");

		String logGroupName = "ysk-cloudwatch-appender-lg"; // args[0];
		String logStreamName = "ysk-cloudwatch-appender-ls"; // args[1];

		CloudWatchLogsClient cloudWatchLogsClient = CloudWatchLogsClient.builder().region(awsRegion).build();

		String argStr;
		if (arg == null) {
			argStr = "";
		} else {
			argStr = ": " + arg.toString();
		}

		InputLogEvent logEvent = InputLogEvent.builder()
				.message("Hello world from " + MyDebugFunctions.class.getName() + argStr)
				.timestamp(System.currentTimeMillis()).build();
		PutLogEventsRequest req = PutLogEventsRequest.builder().logGroupName(logGroupName).logStreamName(logStreamName)
				.logEvents(Collections.singleton(logEvent)).build();

		PutLogEventsResponse res = cloudWatchLogsClient.putLogEvents(req);
		return res.toString();
	}


	/**
	 * Fileを読み込む。ファイルが存在しない場合はnullを返却する。
	 * 
	 * pom.xmlにMuleのFileコネクタを追加しなくても動作するようにする意図。
	 * @param path
	 * @return
	 * @throws IOException
	 */
	public static InputStream readFileOrNull(String path) throws IOException {
		try {
		byte[] fileContents = Files.readAllBytes(Path.of(path));
			return new ByteArrayInputStream(fileContents);
		} catch (FileNotFoundException e) {
			return null;
		}
	}
}
