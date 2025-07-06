package myapp;

import java.io.IOException;
import java.io.UncheckedIOException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;
import software.amazon.awssdk.http.AbortableInputStream;
import software.amazon.awssdk.http.ContentStreamProvider;
import software.amazon.awssdk.http.HttpExecuteRequest;
import software.amazon.awssdk.http.HttpExecuteResponse;
import software.amazon.awssdk.http.SdkHttpClient;
import software.amazon.awssdk.http.SdkHttpMethod;
import software.amazon.awssdk.http.SdkHttpRequest;
import software.amazon.awssdk.http.apache.ApacheHttpClient;
import software.amazon.awssdk.http.auth.aws.signer.AwsV4HttpSigner;
import software.amazon.awssdk.http.auth.spi.signer.SignedRequest;
import software.amazon.awssdk.identity.spi.AwsCredentialsIdentity;

public class MyFunctions {
	private static final Logger LOG = LoggerFactory.getLogger("MyFunctions");
	
	public static byte[] sendTraceToAwsXray(byte[] data) {
		return sendTraceToAwsXray("ap-northeast-1", data);
	}

	public static byte[] sendTraceToAwsXray(String awsRegion, byte[] data) {
		return sendTraceToAwsXray("https://xray." + awsRegion + ".amazonaws.com/v1/traces", awsRegion, data);
	}

	public static byte[] sendTraceToAwsXray(String endpoint, String awsRegion, byte[] data) {
		// https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-OTLPEndpoint.html
		// > The endpoint authenticates callers using Signature 4 authentication.
		// https://qiita.com/cozima/items/84aabaa8f1b827e6b36b
		// > AWS SDK for Java 2.10.12以前では、AwsS3V4Signerを使用して、Presigned URLを生成していました
		// https://github.com/aws/aws-sdk-java-v2/blob/master/core/auth/src/main/java/software/amazon/awssdk/auth/signer/Aws4Signer.java
		// > @deprecated Use {@code software.amazon.awssdk.http.auth.aws.signer.AwsV4HttpSigner} from the 'http-auth-aws' module.
		// https://sdk.amazonaws.com/java/api/latest/software/amazon/awssdk/http/auth/aws/signer/AwsV4HttpSigner.html
		// > Using the AwsV4HttpSigner
		AwsV4HttpSigner signer = AwsV4HttpSigner.create();

		// Specify AWS credentials. Credential providers that are used by the SDK by
		// default are available in the module "auth" (e.g. DefaultCredentialsProvider).
		//AwsCredentialsIdentity credentials = AwsSessionCredentialsIdentity.create("skid", "akid", "stok");
		AwsCredentialsIdentity credentials = DefaultCredentialsProvider.builder().build().resolveCredentials();

		// MEMO
		// java.lang.RuntimeException: httpStatuCode=400
		// httpStatusCode=400 httpStatusText=Optional[Bad Request] httpResBody=The OTLP API is supported with CloudWatch Logs as a Trace Segment Destination. Please enable the CloudWatch Logs destination for your traces using the UpdateTraceSegmentDestination API (https://docs.aws.amazon.com/xray/latest/api/API_UpdateTraceSegmentDestination.html)
		// Introducing CloudWatch Application Signals with Transaction Search. This new capability allows you to send 100% of your application spans into CloudWatch Logs without any throttling, providing you with comprehensive visibility into your applications at a more competitive price point. Set up Transaction Search and check the new pricing model.
		// httpStatusCode=400 httpStatusText=Optional[Bad Request] httpResBody=The OTLP API is supported with CloudWatch Logs as a Trace Segment Destination. Please enable the CloudWatch Logs destination for your traces using the UpdateTraceSegmentDestination API (https://docs.aws.amazon.com/xray/latest/api/API_UpdateTraceSegmentDestination.html)

		// Create the HTTP request to be signed
		SdkHttpRequest httpRequest = SdkHttpRequest.builder().uri(endpoint).method(SdkHttpMethod.POST)
				.putHeader("Content-Type", "application/x-protobuf").build();
		// TODO 1回のリクエスト当たりの最大個数と最大byte数を超えていたら、分割して送信する。

		// Create the request payload to be signed
		ContentStreamProvider requestPayload = //
				// ContentStreamProvider.fromUtf8String("Hello, World!");
				ContentStreamProvider.fromByteArray(data);

		// Sign the request. Some services require custom signing configuration properties (e.g. S3).
		// See AwsV4HttpSigner and AwsV4FamilyHttpSigner for the available signing options.
		//   Note: The S3Client class below requires a dependency on the 's3' module. Alternatively, the
		//   signing name can be hard-coded because it is guaranteed to not change.
		SignedRequest signedRequest = signer
				.sign(r -> r.identity(credentials).request(httpRequest).payload(requestPayload)
						.putProperty(AwsV4HttpSigner.SERVICE_SIGNING_NAME, "xray" /* S3Client.SERVICE_NAME */)
						.putProperty(AwsV4HttpSigner.REGION_NAME, awsRegion /* "us-west-2" */)); //
		// .putProperty(AwsV4HttpSigner.DOUBLE_URL_ENCODE, false) // Required for S3 only
		// .putProperty(AwsV4HttpSigner.NORMALIZE_PATH, false)); // Required for S3 only

		// Create and HTTP client and send the request. ApacheHttpClient requires the 'apache-client' module.
		try (SdkHttpClient httpClient = ApacheHttpClient.create()) {
			HttpExecuteRequest httpExecuteRequest = HttpExecuteRequest.builder().request(signedRequest.request())
					.contentStreamProvider(signedRequest.payload().orElse(null)).build();

			HttpExecuteResponse httpResponse = httpClient.prepareRequest(httpExecuteRequest).call();

			LOG.info("HTTP Status Code: {}", httpResponse.httpResponse().statusCode());
			int httpStatuCode = httpResponse.httpResponse().statusCode();
			if (httpStatuCode != 200) {
				LOG.error("HTTP Status Code: {} {}", httpResponse.httpResponse().statusCode(), toString(httpResponse));
				throw new RuntimeException("httpStatuCode=" + httpStatuCode + "\n" + toString(httpResponse));
			}
		} catch (IOException e) {
			System.err.println("HTTP Request Failed.");
			throw new UncheckedIOException(e);
		}
		
		// 以下の対策として、返却する。
		// "Cannot coerce Null (null) to Binary" evaluating expression: "java!myapp::MyFunctions::sendTraceToAwsXray(payload as Binary) as Null".
		return data;
	}

	static String toString(HttpExecuteResponse res) throws IOException {
		StringBuilder sb = new StringBuilder() //
				.append("httpStatusCode=").append(res.httpResponse().statusCode()) //
				.append(" httpStatusText=").append(res.httpResponse().statusText()) //
				.append(" httpResBody=");

		// protbuf形式なことから先頭に数byteのバイナリデータが付くので、エスケープ出力する。
		// [8, 7, 18, 54, 84, 
		// 6The security token included in the request is invalid.
		byte [] resBodyBytes = res.responseBody().orElse(AbortableInputStream.createEmpty()).readAllBytes();
		// String resBodyString = new String(resBodyBytes, StandardCharsets.ISO_8859_1);
		for (int i = 0; i < resBodyBytes.length; i++) {
			int c = (int) resBodyBytes[i] & 0xff;
			if (' ' <= c && c <= '~') {
				sb.append((char)c);
			} else {
				sb.append("\\%02x".formatted(c));
			}
		}
		return sb.toString();
	}
}
