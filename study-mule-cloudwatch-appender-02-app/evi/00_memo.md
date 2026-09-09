### 
```log
Caused by:
 software.amazon.awssdk.core.exception.SdkClientException:
 
Unable to load credentials from any of the providers in the chain 
AwsCredentialsProviderChain(credentialsProviders=[SystemPropertyCredentialsProvider(), 
EnvironmentVariableCredentialsProvider(), WebIdentityTokenCredentialsProvider(), 
ProfileCredentialsProvider(profileName=default, profileFile=ProfileFile(sections=[profiles, sso-session, services], profiles=[Profile(name=default, properties=[output, source_profile, region, role_arn])])), ContainerCredentialsProvider(), InstanceProfileCredentialsProvider()]) 
:
 [
  SystemPropertyCredentialsProvider():
    Unable to load credentials from system settings. Access key must be specified either via environment variable (AWS_ACCESS_KEY_ID) or system property (aws.accessKeyId)., 
  EnvironmentVariableCredentialsProvider():
    Unable to load credentials from system settings. Access key must be specified either via environment variable (AWS_ACCESS_KEY_ID) or system property (aws.accessKeyId)., 
  WebIdentityTokenCredentialsProvider():
    Either the environment variable AWS_WEB_IDENTITY_TOKEN_FILE or the javaproperty aws.webIdentityTokenFile must be set., 
  ProfileCredentialsProvider(profileName=default, profileFile=ProfileFile(sections=[profiles, sso-session, services], profiles=[Profile(name=default, properties=[output, source_profile, region, role_arn])])):
 
    The source profile of 'default' was configured to be 'profile-with-user-that-can-assume-role', but that source profile has no credentials configured., 
  ContainerCredentialsProvider():
    Cannot fetch credentials from container - neither AWS_CONTAINER_CREDENTIALS_FULL_URI or AWS_CONTAINER_CREDENTIALS_RELATIVE_URI environment variables are set., 
  InstanceProfileCredentialsProvider():
    Failed to load credentials from IMDS.
]
	software.amazon.awssdk.core.exception.SdkClientException$BuilderImpl.build(SdkClientException.java:130)
	software.amazon.awssdk.auth.credentials.AwsCredentialsProviderChain.resolveCredentials(AwsCredentialsProviderChain.java:130)
	software.amazon.awssdk.auth.credentials.internal.LazyAwsCredentialsProvider.resolveCredentials(LazyAwsCredentialsProvider.java:45)
	software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider.resolveCredentials(DefaultCredentialsProvider.java:134)
	software.amazon.awssdk.auth.credentials.AwsCredentialsProvider.resolveIdentity(AwsCredentialsProvider.java:54)
	software.amazon.awssdk.services.cloudwatchlogs.auth.scheme.internal.CloudWatchLogsAuthSchemeInterceptor.lambda$trySelectAuthScheme$4(CloudWatchLogsAuthSchemeInterceptor.java:134)
```

### システムプロパティからaccessKeyとsecretAccessKeyを削除した後
```log
Caused by:
 software.amazon.awssdk.core.exception.SdkClientException:
 Unable to load credentials from any of the providers in the chain AwsCredentialsProviderChain(credentialsProviders=[SystemPropertyCredentialsProvider(), EnvironmentVariableCredentialsProvider(), WebIdentityTokenCredentialsProvider(), ProfileCredentialsProvider(profileName=default, profileFile=ProfileFile(sections=[profiles, sso-session, services], profiles=[Profile(name=default, properties=[output, source_profile, region, role_arn]), Profile(name=profile-with-user-that-can-assume-role, properties=[aws_access_key_id, aws_secret_access_key])])), ContainerCredentialsProvider(), InstanceProfileCredentialsProvider()]) :
 [
  SystemPropertyCredentialsProvider():
    Unable to load credentials from system settings. Access key must be specified either via environment variable (AWS_ACCESS_KEY_ID) or system property (aws.accessKeyId)., 
  EnvironmentVariableCredentialsProvider():
    Unable to load credentials from system settings. Access key must be specified either via environment variable (AWS_ACCESS_KEY_ID) or system property (aws.accessKeyId)., 
  WebIdentityTokenCredentialsProvider():
    Either the environment variable AWS_WEB_IDENTITY_TOKEN_FILE or the javaproperty aws.webIdentityTokenFile must be set., 
  ProfileCredentialsProvider
    (
      profileName=default, 
      profileFile=ProfileFile(sections=[profiles, sso-session, services], 
      profiles=
        [
          Profile(name=default, properties=[output, source_profile, region, role_arn]), 
          Profile(name=profile-with-user-that-can-assume-role, properties=[aws_access_key_id, aws_secret_access_key])
        ])
    ):
    To use assumed roles in the 'default' profile, the 'sts' service module must be on the class path., 
  ContainerCredentialsProvider():
    Cannot fetch credentials from container - neither AWS_CONTAINER_CREDENTIALS_FULL_URI or AWS_CONTAINER_CREDENTIALS_RELATIVE_URI environment variables are set., InstanceProfileCredentialsProvider():
 Failed to load credentials from IMDS.]
```



```log
Caused by: software.amazon.awssdk.core.exception.SdkClientException: 
Unable to load credentials from any of the providers in the chain AwsCredentialsProviderChain(credentialsProviders=[SystemPropertyCredentialsProvider(), EnvironmentVariableCredentialsProvider(), WebIdentityTokenCredentialsProvider(), ProfileCredentialsProvider(profileName=default, profileFile=ProfileFile(sections=[profiles, sso-session, services], profiles=[Profile(name=default, properties=[output, source_profile, region, role_arn]), Profile(name=profile-with-user-that-can-assume-role, properties=[aws_access_key_id, aws_secret_access_key])])), ContainerCredentialsProvider(), InstanceProfileCredentialsProvider()]) : 
[
    SystemPropertyCredentialsProvider(): 
        Unable to load credentials from system settings. Access key must be specified either via environment variable (AWS_ACCESS_KEY_ID) or system property (aws.accessKeyId)., 
    EnvironmentVariableCredentialsProvider(): 
        Unable to load credentials from system settings. Access key must be specified either via environment variable (AWS_ACCESS_KEY_ID) or system property (aws.accessKeyId)., 
    WebIdentityTokenCredentialsProvider(): Either the environment variable AWS_WEB_IDENTITY_TOKEN_FILE or the javaproperty aws.webIdentityTokenFile must be set., 
    ProfileCredentialsProvider(profileName=default, profileFile=ProfileFile(sections=[profiles, sso-session, services], profiles=[Profile(name=default, properties=[output, source_profile, region, role_arn]), Profile(name=profile-with-user-that-can-assume-role, properties=[aws_access_key_id, aws_secret_access_key])])): 
        Unable to execute HTTP request: 
            Connect to vpce-071e8df336a1ac91a-a8b9nsz9.sts.ap-northeast-1.vpce.amazonaws.com:443 [vpce-071e8df336a1ac91a-a8b9nsz9.sts.ap-northeast-1.vpce.amazonaws.com/192.168.3.235] failed: 
                Connect timed out (SDK Attempt Count: 4), 
    ContainerCredentialsProvider(): 
        Cannot fetch credentials from container - neither AWS_CONTAINER_CREDENTIALS_FULL_URI or AWS_CONTAINER_CREDENTIALS_RELATIVE_URI environment variables are set., 
    InstanceProfileCredentialsProvider(): 
    Failed to load credentials from IMDS.
]
```

~/.aws/config
```ini
[default]
region = ap-northeast-1
output = json
role_arn = arn:aws:iam::486807573645:role/ysk-cloudwatch-appender-202609-role
source_profile = profile-with-user-that-can-assume-role
```

~/.aws/credentials
```ini
[profile-with-user-that-can-assume-role]
aws_access_key_id = AKIAXCV76CSG4E2V5H5S
aws_secret_access_key = 秘密の値
```

```json
{
    "システムプロパティ": {
        "aws.～は無し": ""
    },
    "環境変数": {
        "AWS_ENDPOINT_URL_CLOUDWATCH_LOGS": "https://vpce-0292f99f2d9b8b7dc-x61xci3g.logs.ap-northeast-1.vpce.amazonaws.com",
        "AWS_ENDPOINT_URL_STS": "https://vpce-071e8df336a1ac91a-a8b9nsz9.sts.ap-northeast-1.vpce.amazonaws.com",
        "他は省略": ""
    }
}
```

AWS SDKsとツールの設定リファレンス
https://docs.aws.amazon.com/ja_jp/sdkref/latest/guide/settings-reference.html

AWS SDKsとツールを認証するための AWS 認証情報を持つロールの引き受け
https://docs.aws.amazon.com/ja_jp/sdkref/latest/guide/access-assume-role.html

> * credential_source または source_profile から認証情報を取得するように SDK またはツールを設定します。
>   * credential_source を使用してAmazon ECS コンテナ、Amazon EC2 インスタンス、または環境変数から認証情報を取得します。
>   * source_profile を使用して別のプロファイルから認証情報を取得します

AWS SDKsとツールを認証するための AWS 認証情報を持つロールの引き受け
https://docs.aws.amazon.com/ja_jp/sdkref/latest/guide/access-assume-role.html

サービス固有のエンドポイント
https://docs.aws.amazon.com/ja_jp/sdkref/latest/guide/feature-ss-endpoints.html

サービス固有のエンドポイントの識別子
https://docs.aws.amazon.com/ja_jp/sdkref/latest/guide/ss-endpoints-table.html

エンドポイント検出
https://docs.aws.amazon.com/ja_jp/sdkref/latest/guide/feature-endpoint-discovery.html

AWS STS リージョンエンドポイント
https://docs.aws.amazon.com/ja_jp/sdkref/latest/guide/feature-sts-regionalized-endpoints.html


### STSのVPCエンドポイントにアクセスしようとしてTimeoutになったログ
```log
DEBUG 2026-09-10 02:43:25,248 [[MuleRuntime].uber.04: [study-mule-cloudwatch-appender-02-app].my-debug-apiFlow.CPU_LITE @41ac849e] [processor: my-debug-apiFlow/processors/1/route/2/processors/0; event: f4cf1840-ac75-11f1-8acc-70b3d5ebdb26] software.amazon.awssdk.utils.cache.CachedSupplier: (i()) Cached value is stale and will be refreshed.
DEBUG 2026-09-10 02:43:25,248 [[MuleRuntime].uber.04: [study-mule-cloudwatch-appender-02-app].my-debug-apiFlow.CPU_LITE @41ac849e] [processor: my-debug-apiFlow/processors/1/route/2/processors/0; event: f4cf1840-ac75-11f1-8acc-70b3d5ebdb26] software.amazon.awssdk.utils.cache.CachedSupplier: (i()) Refreshing cached value.
DEBUG 2026-09-10 02:43:25,251 [[MuleRuntime].uber.04: [study-mule-cloudwatch-appender-02-app].my-debug-apiFlow.CPU_LITE @41ac849e] [processor: my-debug-apiFlow/processors/1/route/2/processors/0; event: f4cf1840-ac75-11f1-8acc-70b3d5ebdb26] software.amazon.awssdk.core.interceptor.ExecutionInterceptorChain: Creating an interceptor chain that will apply interceptors in the following order: [software.amazon.awssdk.core.internal.interceptor.HttpChecksumValidationInterceptor@53f5caff, software.amazon.awssdk.awscore.interceptor.HelpfulUnknownHostExceptionInterceptor@235b20a9, software.amazon.awssdk.awscore.eventstream.EventStreamInitialRequestInterceptor@231868be, software.amazon.awssdk.awscore.interceptor.TraceIdExecutionInterceptor@1ad1578e, software.amazon.awssdk.services.sts.auth.scheme.internal.StsAuthSchemeInterceptor@678ec419, software.amazon.awssdk.services.sts.endpoints.internal.StsResolveEndpointInterceptor@1d2aee29, software.amazon.awssdk.services.sts.endpoints.internal.StsRequestSetEndpointInterceptor@7d9728aa]
DEBUG 2026-09-10 02:43:25,272 [[MuleRuntime].uber.04: [study-mule-cloudwatch-appender-02-app].my-debug-apiFlow.CPU_LITE @41ac849e] [processor: my-debug-apiFlow/processors/1/route/2/processors/0; event: f4cf1840-ac75-11f1-8acc-70b3d5ebdb26] software.amazon.awssdk.core.interceptor.ExecutionInterceptorChain: Interceptor 'software.amazon.awssdk.services.sts.endpoints.internal.StsRequestSetEndpointInterceptor@7d9728aa' modified the message with its modifyHttpRequest method.
DEBUG 2026-09-10 02:43:25,304 [[MuleRuntime].uber.04: [study-mule-cloudwatch-appender-02-app].my-debug-apiFlow.CPU_LITE @41ac849e] [processor: my-debug-apiFlow/processors/1/route/2/processors/0; event: f4cf1840-ac75-11f1-8acc-70b3d5ebdb26] software.amazon.awssdk.retries.LegacyRetryStrategy: Request attempt 1 token acquired (backoff: 0ms, cost: 0, capacity: 500/500)
DEBUG 2026-09-10 02:43:25,306 [[MuleRuntime].uber.04: [study-mule-cloudwatch-appender-02-app].my-debug-apiFlow.CPU_LITE @41ac849e] [processor: my-debug-apiFlow/processors/1/route/2/processors/0; event: f4cf1840-ac75-11f1-8acc-70b3d5ebdb26] software.amazon.awssdk.request: Sending Request: DefaultSdkHttpFullRequest(httpMethod=POST, protocol=https, host=vpce-071e8df336a1ac91a-a8b9nsz9.sts.ap-northeast-1.vpce.amazonaws.com, encodedPath=, headers=[amz-sdk-invocation-id, Content-Length, Content-Type, User-Agent], queryParameters=[])
DEBUG 2026-09-10 02:43:25,307 [[MuleRuntime].uber.04: [study-mule-cloudwatch-appender-02-app].my-debug-apiFlow.CPU_LITE @41ac849e] [processor: my-debug-apiFlow/processors/1/route/2/processors/0; event: f4cf1840-ac75-11f1-8acc-70b3d5ebdb26] software.amazon.awssdk.core.internal.http.pipeline.stages.SigningStage: Using SelectedAuthScheme: aws.auth#sigv4
DEBUG 2026-09-10 02:43:25,326 [[MuleRuntime].uber.04: [study-mule-cloudwatch-appender-02-app].my-debug-apiFlow.CPU_LITE @41ac849e] [processor: my-debug-apiFlow/processors/1/route/2/processors/0; event: f4cf1840-ac75-11f1-8acc-70b3d5ebdb26] software.amazon.awssdk.http.auth.aws.internal.signer.DefaultV4RequestSigner: AWS4 Canonical Request: POST
/

amz-sdk-invocation-id:a19b610a-d774-5012-0363-5ac6e10d8150
amz-sdk-request:attempt=1; max=4
content-length:166
content-type:application/x-www-form-urlencoded; charset=utf-8
host:vpce-071e8df336a1ac91a-a8b9nsz9.sts.ap-northeast-1.vpce.amazonaws.com
x-amz-content-sha256:65426787f4f93782a39216ed8ddfa6192f3593e5871a76773e2451a54b95b6e7
x-amz-date:20260909T174325Z

amz-sdk-invocation-id;amz-sdk-request;content-length;content-type;host;x-amz-content-sha256;x-amz-date
65426787f4f93782a39216ed8ddfa6192f3593e5871a76773e2451a54b95b6e7
DEBUG 2026-09-10 02:43:25,326 [[MuleRuntime].uber.04: [study-mule-cloudwatch-appender-02-app].my-debug-apiFlow.CPU_LITE @41ac849e] [processor: my-debug-apiFlow/processors/1/route/2/processors/0; event: f4cf1840-ac75-11f1-8acc-70b3d5ebdb26] software.amazon.awssdk.http.auth.aws.internal.signer.DefaultV4RequestSigner: AWS4 Canonical Request Hash: f8f3813258fd193c2c97d9bffa8fc1c4832212c83a4b08b32262896b024dfac0
DEBUG 2026-09-10 02:43:25,326 [[MuleRuntime].uber.04: [study-mule-cloudwatch-appender-02-app].my-debug-apiFlow.CPU_LITE @41ac849e] [processor: my-debug-apiFlow/processors/1/route/2/processors/0; event: f4cf1840-ac75-11f1-8acc-70b3d5ebdb26] software.amazon.awssdk.http.auth.aws.internal.signer.DefaultV4RequestSigner: AWS4 String to sign: AWS4-HMAC-SHA256
20260909T174325Z
20260909/ap-northeast-1/sts/aws4_request
f8f3813258fd193c2c97d9bffa8fc1c4832212c83a4b08b32262896b024dfac0
DEBUG 2026-09-10 02:43:25,345 [[MuleRuntime].uber.04: [study-mule-cloudwatch-appender-02-app].my-debug-apiFlow.CPU_LITE @41ac849e] [processor: my-debug-apiFlow/processors/1/route/2/processors/0; event: f4cf1840-ac75-11f1-8acc-70b3d5ebdb26] org.apache.http.client.protocol.RequestAddCookies: CookieSpec selected: default
DEBUG 2026-09-10 02:43:25,353 [[MuleRuntime].uber.04: [study-mule-cloudwatch-appender-02-app].my-debug-apiFlow.CPU_LITE @41ac849e] [processor: my-debug-apiFlow/processors/1/route/2/processors/0; event: f4cf1840-ac75-11f1-8acc-70b3d5ebdb26] org.apache.http.client.protocol.RequestAuthCache: Auth cache not set in the context
DEBUG 2026-09-10 02:43:25,354 [[MuleRuntime].uber.04: [study-mule-cloudwatch-appender-02-app].my-debug-apiFlow.CPU_LITE @41ac849e] [processor: my-debug-apiFlow/processors/1/route/2/processors/0; event: f4cf1840-ac75-11f1-8acc-70b3d5ebdb26] org.apache.http.impl.conn.PoolingHttpClientConnectionManager: Connection request: [route: {s}->https://vpce-071e8df336a1ac91a-a8b9nsz9.sts.ap-northeast-1.vpce.amazonaws.com:443][total available: 0; route allocated: 0 of 50; total allocated: 0 of 50]
DEBUG 2026-09-10 02:43:25,365 [[MuleRuntime].uber.04: [study-mule-cloudwatch-appender-02-app].my-debug-apiFlow.CPU_LITE @41ac849e] [processor: my-debug-apiFlow/processors/1/route/2/processors/0; event: f4cf1840-ac75-11f1-8acc-70b3d5ebdb26] org.apache.http.impl.conn.PoolingHttpClientConnectionManager: Connection leased: [id: 0][route: {s}->https://vpce-071e8df336a1ac91a-a8b9nsz9.sts.ap-northeast-1.vpce.amazonaws.com:443][total available: 0; route allocated: 1 of 50; total allocated: 1 of 50]
DEBUG 2026-09-10 02:43:25,366 [[MuleRuntime].uber.04: [study-mule-cloudwatch-appender-02-app].my-debug-apiFlow.CPU_LITE @41ac849e] [processor: my-debug-apiFlow/processors/1/route/2/processors/0; event: f4cf1840-ac75-11f1-8acc-70b3d5ebdb26] org.apache.http.impl.execchain.MainClientExec: Opening connection {s}->https://vpce-071e8df336a1ac91a-a8b9nsz9.sts.ap-northeast-1.vpce.amazonaws.com:443
DEBUG 2026-09-10 02:43:25,409 [[MuleRuntime].uber.04: [study-mule-cloudwatch-appender-02-app].my-debug-apiFlow.CPU_LITE @41ac849e] [processor: my-debug-apiFlow/processors/1/route/2/processors/0; event: f4cf1840-ac75-11f1-8acc-70b3d5ebdb26] org.apache.http.impl.conn.DefaultHttpClientConnectionOperator: Connecting to vpce-071e8df336a1ac91a-a8b9nsz9.sts.ap-northeast-1.vpce.amazonaws.com/192.168.3.235:443
DEBUG 2026-09-10 02:43:25,409 [[MuleRuntime].uber.04: [study-mule-cloudwatch-appender-02-app].my-debug-apiFlow.CPU_LITE @41ac849e] [processor: my-debug-apiFlow/processors/1/route/2/processors/0; event: f4cf1840-ac75-11f1-8acc-70b3d5ebdb26] software.amazon.awssdk.http.apache.internal.conn.SdkTlsSocketFactory: Connecting socket to vpce-071e8df336a1ac91a-a8b9nsz9.sts.ap-northeast-1.vpce.amazonaws.com/192.168.3.235:443 with timeout 2000
DEBUG 2026-09-10 02:43:27,411 [[MuleRuntime].uber.04: [study-mule-cloudwatch-appender-02-app].my-debug-apiFlow.CPU_LITE @41ac849e] [processor: my-debug-apiFlow/processors/1/route/2/processors/0; event: f4cf1840-ac75-11f1-8acc-70b3d5ebdb26] org.apache.http.impl.conn.DefaultManagedHttpClientConnection: http-outgoing-0: Shutdown connection
DEBUG 2026-09-10 02:43:27,412 [[MuleRuntime].uber.04: [study-mule-cloudwatch-appender-02-app].my-debug-apiFlow.CPU_LITE @41ac849e] [processor: my-debug-apiFlow/processors/1/route/2/processors/0; event: f4cf1840-ac75-11f1-8acc-70b3d5ebdb26] org.apache.http.impl.execchain.MainClientExec: Connection discarded
DEBUG 2026-09-10 02:43:27,412 [[MuleRuntime].uber.04: [study-mule-cloudwatch-appender-02-app].my-debug-apiFlow.CPU_LITE @41ac849e] [processor: my-debug-apiFlow/processors/1/route/2/processors/0; event: f4cf1840-ac75-11f1-8acc-70b3d5ebdb26] org.apache.http.impl.conn.PoolingHttpClientConnectionManager: Connection released: [id: 0][route: {s}->https://vpce-071e8df336a1ac91a-a8b9nsz9.sts.ap-northeast-1.vpce.amazonaws.com:443][total available: 0; route allocated: 0 of 50; total allocated: 0 of 50]
DEBUG 2026-09-10 02:43:27,414 [[MuleRuntime].uber.04: [study-mule-cloudwatch-appender-02-app].my-debug-apiFlow.CPU_LITE @41ac849e] [processor: my-debug-apiFlow/processors/1/route/2/processors/0; event: f4cf1840-ac75-11f1-8acc-70b3d5ebdb26] software.amazon.awssdk.retries.LegacyRetryStrategy: Request attempt 1 encountered retryable failure.
software.amazon.awssdk.core.exception.SdkClientException: Unable to execute HTTP request: Connect to vpce-071e8df336a1ac91a-a8b9nsz9.sts.ap-northeast-1.vpce.amazonaws.com:443 [vpce-071e8df336a1ac91a-a8b9nsz9.sts.ap-northeast-1.vpce.amazonaws.com/192.168.3.235] failed: Connect timed out
	at software.amazon.awssdk.core.exception.SdkClientException$BuilderImpl.build(SdkClientException.java:130) ~[sdk-core-2.35.10.jar:?]
	at software.amazon.awssdk.core.exception.SdkClientException.create(SdkClientException.java:47) ~[sdk-core-2.35.10.jar:?]
	at software.amazon.awssdk.core.internal.http.pipeline.stages.utils.RetryableStageHelper.setLastException(RetryableStageHelper.java:231) ~[sdk-core-2.35.10.jar:?]
```


### 環境変数からシステムプロパティへ移動した。STSは効いている。
```log
Caused by: software.amazon.awssdk.core.exception.SdkClientException: Unable to load credentials from any of the providers in the chain AwsCredentialsProviderChain(credentialsProviders=[SystemPropertyCredentialsProvider(), EnvironmentVariableCredentialsProvider(), WebIdentityTokenCredentialsProvider(), ProfileCredentialsProvider(profileName=default, profileFile=ProfileFile(sections=[profiles, sso-session, services], profiles=[Profile(name=default, properties=[output, source_profile, region, role_arn]), Profile(name=profile-with-user-that-can-assume-role, properties=[aws_access_key_id, aws_secret_access_key])])), ContainerCredentialsProvider(), InstanceProfileCredentialsProvider()]) : [SystemPropertyCredentialsProvider(): Unable to load credentials from system settings. Access key must be specified either via environment variable (AWS_ACCESS_KEY_ID) or system property (aws.accessKeyId)., EnvironmentVariableCredentialsProvider(): Unable to load credentials from system settings. Access key must be specified either via environment variable (AWS_ACCESS_KEY_ID) or system property (aws.accessKeyId)., WebIdentityTokenCredentialsProvider(): Either the environment variable AWS_WEB_IDENTITY_TOKEN_FILE or the javaproperty aws.webIdentityTokenFile must be set., ProfileCredentialsProvider(profileName=default, profileFile=ProfileFile(sections=[profiles, sso-session, services], profiles=[Profile(name=default, properties=[output, source_profile, region, role_arn]), Profile(name=profile-with-user-that-can-assume-role, properties=[aws_access_key_id, aws_secret_access_key])])): Unable to execute HTTP request: Connect to vpce-071e8df336a1ac91a-a8b9nsz9.sts.ap-northeast-1.vpce.amazonaws.com:80 [vpce-071e8df336a1ac91a-a8b9nsz9.sts.ap-northeast-1.vpce.amazonaws.com/192.168.3.235] failed: Connect timed out (SDK Attempt Count: 4), ContainerCredentialsProvider(): Cannot fetch credentials from container - neither AWS_CONTAINER_CREDENTIALS_FULL_URI or AWS_CONTAINER_CREDENTIALS_RELATIVE_URI environment variables are set., InstanceProfileCredentialsProvider(): Failed to load credentials from IMDS.]
```

```json
{
    "システムプロパティ": {
        "aws.endpointUrlLogs": "http://vpce-0292f99f2d9b8b7dc-x61xci3g.logs.ap-northeast-1.vpce.amazonaws.com",
        "aws.endpointUrlSts": "http://vpce-071e8df336a1ac91a-a8b9nsz9.sts.ap-northeast-1.vpce.amazonaws.com",
        "他は省略":""
    },
    "環境変数": {
        "AWS＿系はなし":""
    }
}
```